import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kuryl_kz/features/location/models/kato_models.dart';
import 'package:kuryl_kz/features/categories/data/category_repository.dart';
import 'package:kuryl_kz/features/marketplace/models/offer_model.dart';
import 'package:kuryl_kz/features/marketplace/models/order_model.dart';
import 'package:kuryl_kz/features/marketplace/services/offer_service.dart';

import 'marketplace_exception.dart';

class AcceptWorkerResult {
  const AcceptWorkerResult({required this.chatId});

  final String chatId;
}

class OrderService {
  OrderService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final CategoryRepository _categoryRepository = CategoryRepository.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _offers =>
      _firestore.collection('offers');

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  Stream<List<MarketplaceOrder>> streamOpenOrders() {
    return _orders
        .where('status', isEqualTo: MarketplaceOrderStatus.open.wire)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => MarketplaceOrder.fromDocument(doc))
              .toList();
          list.sort(_sortByNewest);
          return list;
        });
  }

  Query<Map<String, dynamic>> buildOpenOrdersCoverageQuery({
    required WorkerCoverageMode coverageMode,
    required LocationBreakdown workerLocation,
  }) {
    final openQuery = _orders.where(
      'status',
      isEqualTo: MarketplaceOrderStatus.open.wire,
    );

    switch (coverageMode) {
      case WorkerCoverageMode.exact:
        if (workerLocation.katoCode.trim().isEmpty) {
          return openQuery;
        }
        return openQuery.where('katoCode', isEqualTo: workerLocation.katoCode);
      case WorkerCoverageMode.district:
        if (workerLocation.districtKatoCode.trim().isEmpty) {
          return openQuery;
        }
        return openQuery.where(
          'districtKatoCode',
          isEqualTo: workerLocation.districtKatoCode,
        );
      case WorkerCoverageMode.region:
        if (workerLocation.regionKatoCode.trim().isEmpty) {
          return openQuery;
        }
        return openQuery.where(
          'regionKatoCode',
          isEqualTo: workerLocation.regionKatoCode,
        );
    }
  }

  Stream<List<MarketplaceOrder>> streamOpenOrdersByCoverage({
    required WorkerCoverageMode coverageMode,
    required LocationBreakdown workerLocation,
  }) {
    return buildOpenOrdersCoverageQuery(
      coverageMode: coverageMode,
      workerLocation: workerLocation,
    ).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MarketplaceOrder.fromDocument(doc))
          .toList();
      list.sort(_sortByNewest);
      return list;
    });
  }

  Stream<List<MarketplaceOrder>> streamClientOrders(String clientId) {
    return _orders.where('clientId', isEqualTo: clientId).snapshots().map((
      snapshot,
    ) {
      final list = snapshot.docs
          .map((doc) => MarketplaceOrder.fromDocument(doc))
          .toList();
      list.sort(_sortByNewest);
      return list;
    });
  }

  Stream<List<MarketplaceOrder>> streamWorkerOrders(String workerId) {
    return _orders
        .where('acceptedWorkerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => MarketplaceOrder.fromDocument(doc))
              .toList();
          list.sort(_sortByNewest);
          return list;
        });
  }

  Stream<MarketplaceOrder?> streamOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return MarketplaceOrder.fromDocument(doc);
    });
  }

  Future<MarketplaceOrder?> getOrder(String orderId) async {
    final doc = await _orders.doc(orderId).get();
    if (!doc.exists) return null;
    return MarketplaceOrder.fromDocument(doc);
  }

  Future<List<String>> uploadOrderPhotos({
    required String clientId,
    required List<File> files,
  }) async {
    if (files.isEmpty) return <String>[];

    final urls = <String>[];

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName =
          'order_${clientId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

      final ref = _storage
          .ref()
          .child('uploads')
          .child(clientId)
          .child('images')
          .child('orders')
          .child(fileName);
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future<String> createOrder({
    required String clientId,
    required String title,
    required String categoryId,
    required List<String> categoryPathIds,
    required String categoryRootId,
    required String categoryName,
    required String description,
    required double? budgetPrice,
    required bool negotiable,
    required LocationBreakdown location,
    required List<String> photos,
  }) async {
    if (title.trim().isEmpty) {
      throw const MarketplaceException('Тапсырыс атауын толтырыңыз.');
    }
    if (categoryId.trim().isEmpty) {
      throw const MarketplaceException('Категория міндетті.');
    }
    if (categoryPathIds.isEmpty || categoryRootId.trim().isEmpty) {
      throw const MarketplaceException(
        'Категория жолы толық емес. Қайта таңдаңыз.',
      );
    }
    if (description.trim().isEmpty) {
      throw const MarketplaceException('Сипаттама міндетті.');
    }
    if (!location.isValid) {
      throw const MarketplaceException('Орналасуды таңдаңыз.');
    }

    if (!negotiable && (budgetPrice == null || budgetPrice <= 0)) {
      throw const MarketplaceException(
        'Бағаны дұрыс енгізіңіз немесе "Келісімді" таңдаңыз.',
      );
    }

    // Leaf-only order category save guard for Firestore payloads.
    await _categoryRepository.init();
    final normalizedCategoryId = categoryId.trim();
    final leaf = _categoryRepository.getLeaf(normalizedCategoryId);
    if (leaf == null) {
      throw const MarketplaceException(
        'Тек нақты қызмет санатын (leaf) таңдауға болады.',
      );
    }
    if (categoryPathIds.last != normalizedCategoryId ||
        categoryPathIds.first != categoryRootId.trim()) {
      throw const MarketplaceException(
        'Категория жолы жарамсыз. Санатты қайта таңдаңыз.',
      );
    }

    final order = MarketplaceOrder(
      id: '',
      clientId: clientId,
      title: title.trim(),
      categoryId: normalizedCategoryId,
      categoryPathIds: categoryPathIds,
      categoryRootId: categoryRootId.trim(),
      categoryName: categoryName.trim(),
      description: description.trim(),
      budgetPrice: negotiable ? null : budgetPrice,
      negotiable: negotiable,
      locationShort: location.shortLabel.trim(),
      location: location,
      photos: photos,
      status: MarketplaceOrderStatus.open,
      createdAt: null,
      acceptedWorkerId: null,
      doneByWorker: false,
      doneByClient: false,
      cancelledBy: null,
      cancelReason: null,
      offerWorkerIds: const <String>[],
      offersCount: 0,
      updatedAt: null,
      reviewCreatedAt: null,
    );

    final docRef = _orders.doc();
    await docRef.set(order.toMapForCreate());
    return docRef.id;
  }

  Future<AcceptWorkerResult> acceptWorkerOffer({
    required String orderId,
    required String clientId,
    required String selectedWorkerId,
    String? clientName,
    String? clientAvatarUrl,
    String? workerName,
    String? workerAvatarUrl,
  }) async {
    await _firestore.runTransaction((tx) async {
      final orderRef = _orders.doc(orderId);
      final orderSnap = await tx.get(orderRef);

      if (!orderSnap.exists) {
        throw const MarketplaceException('Тапсырыс табылмады.');
      }

      final order = MarketplaceOrder.fromDocument(orderSnap);

      if (order.clientId != clientId) {
        throw const MarketplaceException(
          'Бұл тапсырысты тек иесі бекіте алады.',
        );
      }

      if (!order.isOpen) {
        throw const MarketplaceException(
          'Бұл тапсырыс басқа шеберге бекітілген немесе жабық.',
        );
      }

      final selectedOfferRef = _offers.doc(
        OfferService.offerDocumentId(
          orderId: orderId,
          workerId: selectedWorkerId,
        ),
      );
      final selectedOfferSnap = await tx.get(selectedOfferRef);
      if (!selectedOfferSnap.exists) {
        throw const MarketplaceException('Таңдалған ұсыныс табылмады.');
      }

      final allWorkerIds = <String>{...order.offerWorkerIds, selectedWorkerId};

      for (final workerId in allWorkerIds) {
        final offerRef = _offers.doc(
          OfferService.offerDocumentId(orderId: orderId, workerId: workerId),
        );
        final offerSnap = await tx.get(offerRef);
        if (!offerSnap.exists) continue;

        tx.update(offerRef, <String, dynamic>{
          'status': workerId == selectedWorkerId
              ? MarketplaceOfferStatus.accepted.wire
              : MarketplaceOfferStatus.rejected.wire,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      tx.update(orderRef, <String, dynamic>{
        'status': MarketplaceOrderStatus.inProgress.wire,
        'acceptedWorkerId': selectedWorkerId,
        'doneByWorker': false,
        'doneByClient': false,
        'cancelledBy': null,
        'cancelReason': null,
        'offerWorkerIds': allWorkerIds.toList(),
        'offersCount': allWorkerIds.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final chatRef = _chats.doc(orderId);
      tx.set(chatRef, <String, dynamic>{
        'orderId': orderId,
        'clientId': clientId,
        'workerId': selectedWorkerId,
        'participants': <String>[clientId, selectedWorkerId],
        'clientName': (clientName ?? '').trim(),
        'clientAvatarUrl': (clientAvatarUrl ?? '').trim(),
        'workerName': (workerName ?? '').trim(),
        'workerAvatarUrl': (workerAvatarUrl ?? '').trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': 'Тапсырыс қабылданды. Чат ашылды.',
        'lastMessageType': 'text',
        'lastSenderId': clientId,
        'lastMessageAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    return AcceptWorkerResult(chatId: orderId);
  }

  Future<void> markWorkerDone({
    required String orderId,
    required String workerId,
  }) async {
    await _firestore.runTransaction((tx) async {
      final orderRef = _orders.doc(orderId);
      final orderSnap = await tx.get(orderRef);

      if (!orderSnap.exists) {
        throw const MarketplaceException('Тапсырыс табылмады.');
      }

      final order = MarketplaceOrder.fromDocument(orderSnap);

      if (order.acceptedWorkerId != workerId) {
        throw const MarketplaceException(
          'Бұл әрекет тек бекітілген шеберге қолжетімді.',
        );
      }

      if (!order.isInProgress && !order.isCompleted) {
        throw const MarketplaceException(
          'Бұл тапсырыс бойынша аяқтау белгілеу мүмкін емес.',
        );
      }

      final doneByWorker = true;
      final doneByClient = order.doneByClient;

      tx.update(orderRef, <String, dynamic>{
        'doneByWorker': doneByWorker,
        'status': doneByWorker && doneByClient
            ? MarketplaceOrderStatus.completed.wire
            : MarketplaceOrderStatus.inProgress.wire,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> markClientDone({
    required String orderId,
    required String clientId,
  }) async {
    await _firestore.runTransaction((tx) async {
      final orderRef = _orders.doc(orderId);
      final orderSnap = await tx.get(orderRef);

      if (!orderSnap.exists) {
        throw const MarketplaceException('Тапсырыс табылмады.');
      }

      final order = MarketplaceOrder.fromDocument(orderSnap);

      if (order.clientId != clientId) {
        throw const MarketplaceException(
          'Бұл әрекет тек тапсырыс иесіне қолжетімді.',
        );
      }

      if (!order.isInProgress && !order.isCompleted) {
        throw const MarketplaceException('Тапсырыс бұл күйде расталмайды.');
      }

      final doneByClient = true;
      final doneByWorker = order.doneByWorker;

      tx.update(orderRef, <String, dynamic>{
        'doneByClient': doneByClient,
        'status': doneByWorker && doneByClient
            ? MarketplaceOrderStatus.completed.wire
            : MarketplaceOrderStatus.inProgress.wire,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> cancelOrder({
    required String orderId,
    required String actorId,
    required String actorRole,
    String? reason,
  }) async {
    final orderRef = _orders.doc(orderId);
    final orderSnap = await orderRef.get();

    if (!orderSnap.exists) {
      throw const MarketplaceException('Тапсырыс табылмады.');
    }

    final order = MarketplaceOrder.fromDocument(orderSnap);
    final normalizedRole = actorRole.trim().toLowerCase();
    final normalizedReason = (reason ?? '').trim();

    if (order.isCancelled) {
      throw const MarketplaceException('Тапсырыс бұрыннан тоқтатылған.');
    }

    if (order.isCompleted) {
      throw const MarketplaceException(
        'Аяқталған тапсырысты тоқтату мүмкін емес.',
      );
    }

    if (order.isOpen) {
      if (normalizedRole != 'client' || order.clientId != actorId) {
        throw const MarketplaceException(
          'OPEN тапсырысты тек тапсырыс иесі тоқтата алады.',
        );
      }
    } else if (order.isInProgress) {
      final isClient = normalizedRole == 'client' && order.clientId == actorId;
      final isWorker =
          normalizedRole == 'worker' && order.acceptedWorkerId == actorId;

      if (!isClient && !isWorker) {
        throw const MarketplaceException(
          'IN_PROGRESS тапсырысты тек қатысушылар тоқтата алады.',
        );
      }

      if (normalizedReason.isEmpty) {
        throw const MarketplaceException(
          'Орындалудағы тапсырысты тоқтату үшін себеп міндетті.',
        );
      }
    }

    final orderCancelPatch = <String, dynamic>{
      'status': MarketplaceOrderStatus.cancelled.wire,
      'cancelledBy': normalizedRole,
      'cancelReason': normalizedReason,
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (order.isInProgress) {
      await orderRef.update(orderCancelPatch);
      return;
    }

    await _firestore.runTransaction((tx) async {
      final freshOrderSnap = await tx.get(orderRef);
      if (!freshOrderSnap.exists) {
        throw const MarketplaceException('Тапсырыс табылмады.');
      }

      final freshOrder = MarketplaceOrder.fromDocument(freshOrderSnap);
      if (!freshOrder.isOpen) {
        throw const MarketplaceException(
          'OPEN тапсырыс күйі өзгерді. Қайтадан көріңіз.',
        );
      }
      if (normalizedRole != 'client' || freshOrder.clientId != actorId) {
        throw const MarketplaceException(
          'OPEN тапсырысты тек тапсырыс иесі тоқтата алады.',
        );
      }

      tx.update(orderRef, orderCancelPatch);

      for (final workerId in freshOrder.offerWorkerIds) {
        final offerRef = _offers.doc(
          OfferService.offerDocumentId(orderId: orderId, workerId: workerId),
        );
        final offerSnap = await tx.get(offerRef);
        if (!offerSnap.exists) continue;

        tx.update(offerRef, <String, dynamic>{
          'status': MarketplaceOfferStatus.rejected.wire,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final chatRef = _chats.doc(orderId);
      final chatSnap = await tx.get(chatRef);

      if (chatSnap.exists) {
        tx.set(chatRef, <String, dynamic>{
          'lastMessage': 'Order cancelled',
          'lastMessageType': 'text',
          'lastSenderId': actorId,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  static int _sortByNewest(MarketplaceOrder a, MarketplaceOrder b) {
    final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }
}
