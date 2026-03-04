import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kuryl_kz/features/marketplace/models/offer_model.dart';
import 'package:kuryl_kz/features/marketplace/models/order_model.dart';

import 'marketplace_exception.dart';

class OfferSubmitResult {
  const OfferSubmitResult({required this.updatedExisting});

  final bool updatedExisting;
}

class OfferService {
  OfferService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _offers =>
      _firestore.collection('offers');

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  static String offerDocumentId({
    required String orderId,
    required String workerId,
  }) {
    return MarketplaceOffer.documentId(orderId: orderId, workerId: workerId);
  }

  DocumentReference<Map<String, dynamic>> offerRef({
    required String orderId,
    required String workerId,
  }) {
    return _offers.doc(offerDocumentId(orderId: orderId, workerId: workerId));
  }

  Stream<List<MarketplaceOffer>> streamOffersForOrder(String orderId) {
    return _offers.where('orderId', isEqualTo: orderId).snapshots().map((
      snapshot,
    ) {
      final list = snapshot.docs
          .map((doc) => MarketplaceOffer.fromDocument(doc))
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Stream<MarketplaceOffer?> streamWorkerOffer({
    required String orderId,
    required String workerId,
  }) {
    return offerRef(orderId: orderId, workerId: workerId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return MarketplaceOffer.fromDocument(doc);
    });
  }

  Future<OfferSubmitResult> sendOrUpdateOffer({
    required String orderId,
    required String workerId,
    required double? offeredPrice,
    required bool sameAsBudget,
    String? message,
  }) async {
    final updatedExisting = await _firestore.runTransaction<bool>((tx) async {
      final orderRef = _orders.doc(orderId);
      final orderSnap = await tx.get(orderRef);

      if (!orderSnap.exists) {
        throw const MarketplaceException('Тапсырыс табылмады.');
      }

      final order = MarketplaceOrder.fromDocument(orderSnap);
      if (!order.isOpen) {
        throw const MarketplaceException(
          'Бұл тапсырыс енді ашық емес. Ұсыныс жіберу мүмкін емес.',
        );
      }

      final resolvedPrice = sameAsBudget ? order.budgetPrice : offeredPrice;
      if (resolvedPrice == null || resolvedPrice <= 0) {
        throw const MarketplaceException('Ұсыныс бағасын дұрыс енгізіңіз.');
      }

      final ref = offerRef(orderId: orderId, workerId: workerId);
      final offerSnap = await tx.get(ref);

      final existing = offerSnap.data();
      final createdAtField = existing != null && existing['createdAt'] != null
          ? existing['createdAt']
          : FieldValue.serverTimestamp();

      tx.set(ref, <String, dynamic>{
        'orderId': orderId,
        'workerId': workerId,
        'offeredPrice': resolvedPrice,
        'message': (message ?? '').trim(),
        'status': MarketplaceOfferStatus.sent.wire,
        'createdAt': createdAtField,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final workers = <String>{...order.offerWorkerIds, workerId};
      tx.update(orderRef, <String, dynamic>{
        'offerWorkerIds': workers.toList(),
        'offersCount': workers.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return offerSnap.exists;
    });

    return OfferSubmitResult(updatedExisting: updatedExisting);
  }
}
