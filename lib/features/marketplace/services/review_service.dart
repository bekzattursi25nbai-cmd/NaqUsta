import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kuryl_kz/features/marketplace/models/order_model.dart';
import 'package:kuryl_kz/features/marketplace/models/review_model.dart';

import 'marketplace_exception.dart';

class ReviewService {
  ReviewService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('reviews');

  Stream<List<MarketplaceReview>> streamWorkerReviews(String workerId) {
    return _reviews.where('workerId', isEqualTo: workerId).snapshots().map((
      snapshot,
    ) {
      final list = snapshot.docs
          .map((doc) => MarketplaceReview.fromDocument(doc))
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Future<void> submitReview({
    required String orderId,
    required String clientId,
    required int rating,
    String? text,
    String? clientName,
  }) async {
    if (rating < 1 || rating > 5) {
      throw const MarketplaceException('Рейтинг 1 мен 5 арасында болуы керек.');
    }

    await _firestore.runTransaction((tx) async {
      final orderRef = _orders.doc(orderId);
      final orderSnap = await tx.get(orderRef);

      if (!orderSnap.exists) {
        throw const MarketplaceException('Тапсырыс табылмады.');
      }

      final order = MarketplaceOrder.fromDocument(orderSnap);

      if (order.clientId != clientId) {
        throw const MarketplaceException(
          'Пікірді тек тапсырыс иесі жаза алады.',
        );
      }

      if (!order.isCompleted) {
        throw const MarketplaceException(
          'Пікір тек COMPLETED күйінен кейін рұқсат етіледі.',
        );
      }

      if ((order.acceptedWorkerId ?? '').isEmpty) {
        throw const MarketplaceException('Шебер табылмады.');
      }

      final reviewRef = _reviews.doc(orderId);
      final reviewSnap = await tx.get(reviewRef);
      if (reviewSnap.exists) {
        throw const MarketplaceException(
          'Бұл тапсырыс бойынша пікір бұрын берілген.',
        );
      }

      final reviewText = (text ?? '').trim();
      final authorName = (clientName ?? '').trim().isEmpty ? 'Клиент' : clientName!.trim();

      tx.set(reviewRef, <String, dynamic>{
        'orderId': orderId,
        'workerId': order.acceptedWorkerId,
        'clientId': clientId,
        'rating': rating,
        'text': reviewText,
        'clientName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(orderRef, <String, dynamic>{
        'reviewCreatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
