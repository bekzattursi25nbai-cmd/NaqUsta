import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kuryl_kz/features/location/models/kato_models.dart';
import 'package:kuryl_kz/features/marketplace/services/offer_service.dart';
import 'package:kuryl_kz/features/marketplace/services/order_service.dart';
import 'package:kuryl_kz/features/marketplace/services/review_service.dart';
import 'package:kuryl_kz/firebase_options.dart';

const String _projectId = 'naqusta';
const String _password = 'Pass123!';
const int _firestorePort = 8080;
const int _authPort = 9099;
const int _storagePort = 9199;

const LocationBreakdown _almatyOrderLocation = LocationBreakdown(
  id: 1001,
  katoCode: '750000000',
  kind: 'city',
  name: KatoLocalizedName(kz: 'Алматы', ru: 'Алматы', en: 'Almaty'),
  regionKatoCode: '750000000',
  districtKatoCode: '750000000',
  shortLabel: 'Almaty',
  fullLabel: 'Almaty',
  regionLabel: 'Almaty',
  districtLabel: 'Almaty',
  pathIds: <int>[1001],
  pathKatoCodes: <String>['750000000'],
);

const LocationBreakdown _astanaOrderLocation = LocationBreakdown(
  id: 1002,
  katoCode: '710000000',
  kind: 'city',
  name: KatoLocalizedName(kz: 'Астана', ru: 'Астана', en: 'Astana'),
  regionKatoCode: '710000000',
  districtKatoCode: '710000000',
  shortLabel: 'Astana',
  fullLabel: 'Astana',
  regionLabel: 'Astana',
  districtLabel: 'Astana',
  pathIds: <int>[1002],
  pathKatoCodes: <String>['710000000'],
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseAuth auth;
  late FirebaseFirestore firestore;
  late FirebaseStorage storage;
  late String emulatorHost;

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    emulatorHost = _resolveEmulatorHost();
    auth = FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;
    storage = FirebaseStorage.instance;

    auth.useAuthEmulator(emulatorHost, _authPort);
    firestore.useFirestoreEmulator(emulatorHost, _firestorePort);
    storage.useStorageEmulator(emulatorHost, _storagePort);

    firestore.settings = const Settings(
      persistenceEnabled: false,
      sslEnabled: false,
    );
  });

  setUp(() async {
    await auth.signOut();
    await _clearAuthEmulator(projectId: _projectId, host: emulatorHost);
    await _clearFirestoreEmulator(projectId: _projectId, host: emulatorHost);
  });

  testWidgets(
    '1-3) client creates order, worker sees OPEN, worker sends offer, client sees offer',
    (_) async {
      final seed = await _seedUsers(auth: auth, firestore: firestore);
      final orderService = OrderService(firestore: firestore, storage: storage);
      final offerService = OfferService(firestore: firestore);

      await _signIn(auth, seed.client);
      final orderId = await orderService.createOrder(
        clientId: seed.client.uid,
        title: 'Install light fixture',
        categoryId: 'electric.socket_switch',
        categoryPathIds: const <String>[
          'electric',
          'electric.lighting',
          'electric.socket_switch',
        ],
        categoryRootId: 'electric',
        categoryName: 'Socket / switch',
        description: 'Need installation in kitchen',
        budgetPrice: 15000,
        negotiable: false,
        location: _almatyOrderLocation,
        photos: const <String>[],
      );

      final createdOrderDoc = await firestore
          .collection('orders')
          .doc(orderId)
          .get();
      expect(createdOrderDoc.exists, isTrue);
      expect(createdOrderDoc.data()?['clientId'], seed.client.uid);
      expect(createdOrderDoc.data()?['status'], 'OPEN');

      await _signIn(auth, seed.worker);
      final workerOpenFeed = await orderService
          .streamOpenOrders()
          .firstWhere((orders) => orders.any((o) => o.id == orderId))
          .timeout(const Duration(seconds: 10));
      expect(workerOpenFeed.any((o) => o.id == orderId), isTrue);

      final workerOrderDetail = await orderService.getOrder(orderId);
      expect(workerOrderDetail, isNotNull);
      expect(workerOrderDetail!.id, orderId);
      expect(workerOrderDetail.isOpen, isTrue);

      await offerService.sendOrUpdateOffer(
        orderId: orderId,
        workerId: seed.worker.uid,
        offeredPrice: 14500,
        sameAsBudget: false,
        message: 'Can do this today',
      );

      await _signIn(auth, seed.client);
      final offersQuery = await firestore
          .collection('offers')
          .where('orderId', isEqualTo: orderId)
          .get();
      expect(offersQuery.docs, isNotEmpty);
      expect(offersQuery.docs.first.data()['workerId'], seed.worker.uid);
    },
  );

  testWidgets(
    '4-6) accept -> IN_PROGRESS + chat + removed OPEN, done/confirm -> COMPLETED, review exists',
    (_) async {
      final seed = await _seedUsers(auth: auth, firestore: firestore);
      final orderService = OrderService(firestore: firestore, storage: storage);
      final offerService = OfferService(firestore: firestore);
      final reviewService = ReviewService(firestore: firestore);

      await _signIn(auth, seed.client);
      final orderId = await orderService.createOrder(
        clientId: seed.client.uid,
        title: 'Replace faucet',
        categoryId: 'plumbing.sink_install',
        categoryPathIds: const <String>[
          'plumbing',
          'plumbing.install',
          'plumbing.sink_install',
        ],
        categoryRootId: 'plumbing',
        categoryName: 'Sink install',
        description: 'Kitchen faucet replacement',
        budgetPrice: 22000,
        negotiable: false,
        location: _astanaOrderLocation,
        photos: const <String>[],
      );

      await _signIn(auth, seed.worker);
      await offerService.sendOrUpdateOffer(
        orderId: orderId,
        workerId: seed.worker.uid,
        offeredPrice: 21000,
        sameAsBudget: false,
        message: 'Can do this today',
      );

      await _signIn(auth, seed.client);
      await orderService.acceptWorkerOffer(
        orderId: orderId,
        clientId: seed.client.uid,
        selectedWorkerId: seed.worker.uid,
        clientName: 'Client User',
        workerName: 'Worker User',
      );

      final inProgressOrder = await firestore
          .collection('orders')
          .doc(orderId)
          .get();
      expect(inProgressOrder.exists, isTrue);
      expect(inProgressOrder.data()?['status'], 'IN_PROGRESS');
      expect(inProgressOrder.data()?['acceptedWorkerId'], seed.worker.uid);

      final chatDoc = await firestore.collection('chats').doc(orderId).get();
      expect(chatDoc.exists, isTrue);
      expect(chatDoc.data()?['orderId'], orderId);
      expect(chatDoc.data()?['clientId'], seed.client.uid);
      expect(chatDoc.data()?['workerId'], seed.worker.uid);

      await _signIn(auth, seed.worker);
      final workerOpenFeed = await orderService
          .streamOpenOrders()
          .first
          .timeout(const Duration(seconds: 10));
      expect(workerOpenFeed.any((o) => o.id == orderId), isFalse);

      await orderService.markWorkerDone(
        orderId: orderId,
        workerId: seed.worker.uid,
      );
      final afterWorkerDone = await firestore
          .collection('orders')
          .doc(orderId)
          .get();
      expect(afterWorkerDone.data()?['doneByWorker'], isTrue);
      expect(afterWorkerDone.data()?['status'], 'IN_PROGRESS');

      await _signIn(auth, seed.client);
      await orderService.markClientDone(
        orderId: orderId,
        clientId: seed.client.uid,
      );

      final completedOrder = await firestore
          .collection('orders')
          .doc(orderId)
          .get();
      expect(completedOrder.data()?['doneByWorker'], isTrue);
      expect(completedOrder.data()?['doneByClient'], isTrue);
      expect(completedOrder.data()?['status'], 'COMPLETED');

      await reviewService.submitReview(
        orderId: orderId,
        clientId: seed.client.uid,
        rating: 5,
        text: 'Great work',
        clientName: 'Client User',
      );

      final reviewDoc = await firestore
          .collection('reviews')
          .doc(orderId)
          .get();
      expect(reviewDoc.exists, isTrue);
      expect(reviewDoc.data()?['workerId'], seed.worker.uid);
      expect(reviewDoc.data()?['clientId'], seed.client.uid);
      expect(reviewDoc.data()?['rating'], 5);

      final orderAfterReview = await firestore
          .collection('orders')
          .doc(orderId)
          .get();
      expect(orderAfterReview.data()?['reviewCreatedAt'], isNotNull);

      final workerDoc = await firestore
          .collection('workers')
          .doc(seed.worker.uid)
          .get();
      final workerData = workerDoc.data() ?? const <String, dynamic>{};
      if (workerData.containsKey('ratingCount')) {
        expect(workerData['ratingCount'], isA<int>());
      }
      if (workerData.containsKey('ratingAvg')) {
        expect(workerData['ratingAvg'], isA<num>());
      }
    },
  );
}

String _resolveEmulatorHost() {
  if (kIsWeb) return '127.0.0.1';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return '10.0.2.2';
    default:
      return '127.0.0.1';
  }
}

Future<void> _clearFirestoreEmulator({
  required String projectId,
  required String host,
}) async {
  final uri = Uri.parse(
    'http://$host:$_firestorePort/emulator/v1/projects/$projectId/databases/(default)/documents',
  );
  await _sendDelete(uri);
}

Future<void> _clearAuthEmulator({
  required String projectId,
  required String host,
}) async {
  final uri = Uri.parse(
    'http://$host:$_authPort/emulator/v1/projects/$projectId/accounts',
  );
  await _sendDelete(uri);
}

Future<void> _sendDelete(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.deleteUrl(uri);
    final response = await request.close();
    final body = await utf8.decodeStream(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Failed emulator reset ${uri.path}: ${response.statusCode} $body',
      );
    }
  } finally {
    client.close(force: true);
  }
}

Future<_SeedUsersResult> _seedUsers({
  required FirebaseAuth auth,
  required FirebaseFirestore firestore,
}) async {
  final client = await _createAuthUser(auth, prefix: 'client');
  await firestore.collection('users').doc(client.uid).set(<String, dynamic>{
    'uid': client.uid,
    'role': 'client',
    'name': 'Client User',
    'phone': '+77000000001',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'created_at': FieldValue.serverTimestamp(),
    'updated_at': FieldValue.serverTimestamp(),
  });

  await auth.signOut();

  final worker = await _createAuthUser(auth, prefix: 'worker');
  await firestore.collection('workers').doc(worker.uid).set(<String, dynamic>{
    'uid': worker.uid,
    'role': 'worker',
    'fullName': 'Worker User',
    'phone': '+77000000002',
    'city': 'Almaty',
    'district': 'Bostandyk',
    'village': 'Center',
    'location': 'Almaty, Bostandyk, Center',
    'specialty': 'Electrician',
    'specialties': <String>['Electrician'],
    'services': <String>['Electrician'],
    'skills': <String>['Electrician'],
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'created_at': FieldValue.serverTimestamp(),
    'updated_at': FieldValue.serverTimestamp(),
  });

  await auth.signOut();
  return _SeedUsersResult(client: client, worker: worker);
}

Future<_TestUser> _createAuthUser(
  FirebaseAuth auth, {
  required String prefix,
}) async {
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final email = '$prefix.$stamp@test.dev';
  final credential = await auth.createUserWithEmailAndPassword(
    email: email,
    password: _password,
  );

  return _TestUser(
    uid: credential.user!.uid,
    email: email,
    password: _password,
  );
}

Future<void> _signIn(FirebaseAuth auth, _TestUser user) async {
  await auth.signOut();
  await auth.signInWithEmailAndPassword(
    email: user.email,
    password: user.password,
  );
}

class _SeedUsersResult {
  const _SeedUsersResult({required this.client, required this.worker});

  final _TestUser client;
  final _TestUser worker;
}

class _TestUser {
  const _TestUser({
    required this.uid,
    required this.email,
    required this.password,
  });

  final String uid;
  final String email;
  final String password;
}
