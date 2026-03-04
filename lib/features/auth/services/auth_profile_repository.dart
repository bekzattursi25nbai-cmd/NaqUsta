import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kuryl_kz/features/auth/models/auth_role.dart';

class AuthProfileException implements Exception {
  final String message;

  const AuthProfileException(this.message);

  @override
  String toString() => message;
}

enum AuthProfileStatus { client, worker, missing, conflict }

class AuthProfileLookupResult {
  final AuthProfileStatus status;
  final Map<String, dynamic>? clientData;

  const AuthProfileLookupResult({required this.status, this.clientData});
}

class AuthProfileRepository {
  final FirebaseFirestore _firestore;

  AuthProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<AuthProfileLookupResult> lookupByUid(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    final workerRef = _firestore.collection('workers').doc(uid);

    final snapshots = await Future.wait([userRef.get(), workerRef.get()]);

    final userDoc = snapshots[0];
    final workerDoc = snapshots[1];

    if (userDoc.exists && workerDoc.exists) {
      final role = (userDoc.data()?['role'] ?? '').toString();
      if (role.isEmpty || role == AuthRole.worker.value) {
        return const AuthProfileLookupResult(status: AuthProfileStatus.worker);
      }
      return const AuthProfileLookupResult(status: AuthProfileStatus.conflict);
    }

    if (workerDoc.exists) {
      return const AuthProfileLookupResult(status: AuthProfileStatus.worker);
    }

    if (userDoc.exists) {
      final data = userDoc.data();
      final role = (data?['role'] ?? '').toString();
      if (role == AuthRole.worker.value) {
        return const AuthProfileLookupResult(status: AuthProfileStatus.missing);
      }
      return AuthProfileLookupResult(
        status: AuthProfileStatus.client,
        clientData: data,
      );
    }

    return const AuthProfileLookupResult(status: AuthProfileStatus.missing);
  }

  Future<void> createClientProfile({
    required String uid,
    required String phone,
    required String name,
    String? city,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final workerRef = _firestore.collection('workers').doc(uid);
    final publicProfileRef = _firestore.collection('public_profiles').doc(uid);

    await _firestore.runTransaction((txn) async {
      final workerSnap = await txn.get(workerRef);
      if (workerSnap.exists) {
        throw const AuthProfileException(
          'Бұл нөмір шебер ретінде тіркелген. Рөлді өзгертуге болмайды.',
        );
      }

      final userSnap = await txn.get(userRef);
      if (userSnap.exists) {
        final role = (userSnap.data()?['role'] ?? '').toString();
        if (role.isNotEmpty && role != AuthRole.client.value) {
          throw const AuthProfileException('Рөлді өзгертуге болмайды.');
        }
        return;
      }

      final payload = <String, dynamic>{
        'uid': uid,
        'phone': phone,
        'name': name.trim().isEmpty ? 'Клиент' : name.trim(),
        'city': (city ?? '').trim(),
        'role': AuthRole.client.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      txn.set(userRef, payload);
      txn.set(publicProfileRef, <String, dynamic>{
        'displayName': payload['name'],
        'avatarUrl': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> createWorkerProfile({
    required String uid,
    required String phone,
    required String fullName,
    required String city,
    required String district,
    required String village,
    required List<String> specialties,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final workerRef = _firestore.collection('workers').doc(uid);

    final cleanedSpecialties = specialties
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    if (cleanedSpecialties.isEmpty) {
      throw const AuthProfileException('Кемінде 1 мамандық таңдаңыз.');
    }

    await _firestore.runTransaction((txn) async {
      final userSnap = await txn.get(userRef);
      if (userSnap.exists) {
        final role = (userSnap.data()?['role'] ?? '').toString();
        if (role.isNotEmpty && role != AuthRole.worker.value) {
          throw const AuthProfileException(
            'Бұл нөмір тапсырыс беруші ретінде тіркелген. Рөлді өзгертуге болмайды.',
          );
        }
      }

      final workerSnap = await txn.get(workerRef);
      if (workerSnap.exists) {
        final role = (workerSnap.data()?['role'] ?? '').toString();
        if (role.isNotEmpty && role != AuthRole.worker.value) {
          throw const AuthProfileException('Рөлді өзгертуге болмайды.');
        }
        txn.set(
          userRef,
          _workerUserPayload(
            uid: uid,
            phone: phone,
            fullName: fullName,
            includeCreatedAt: !userSnap.exists,
          ),
          SetOptions(merge: true),
        );
        return;
      }

      final locationShort = <String>[
        city,
        district,
        village,
      ].map((item) => item.trim()).where((item) => item.isNotEmpty).join(', ');

      final payload = <String, dynamic>{
        'uid': uid,
        'phone': phone,
        'fullName': fullName.trim(),
        'firstName': fullName.trim(),
        'city': city.trim(),
        'district': district.trim(),
        'village': village.trim(),
        'location': locationShort,
        'specialty': cleanedSpecialties.first,
        'specialties': cleanedSpecialties,
        'services': cleanedSpecialties,
        'skills': cleanedSpecialties,
        'role': AuthRole.worker.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      txn.set(workerRef, payload);
      txn.set(
        userRef,
        _workerUserPayload(
          uid: uid,
          phone: phone,
          fullName: fullName,
          includeCreatedAt: !userSnap.exists,
        ),
        SetOptions(merge: true),
      );
    });
  }

  Map<String, dynamic> _workerUserPayload({
    required String uid,
    required String phone,
    required String fullName,
    required bool includeCreatedAt,
  }) {
    final payload = <String, dynamic>{
      'uid': uid,
      'phone': phone,
      'name': fullName.trim().isEmpty ? 'Шебер' : fullName.trim(),
      'role': AuthRole.worker.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (includeCreatedAt) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['created_at'] = FieldValue.serverTimestamp();
    }

    return payload;
  }
}
