import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Нәтиже қайтару үшін (UI-де хабар шығару оңай болады)
class AuthResult {
  final bool success;
  final String message;
  final String? uid;

  const AuthResult({required this.success, required this.message, this.uid});

  factory AuthResult.ok({String message = "OK", String? uid}) =>
      AuthResult(success: true, message: message, uid: uid);

  factory AuthResult.fail(String message) =>
      AuthResult(success: false, message: message);
}

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  // -------------------------
  // Public helpers
  // -------------------------

  User? get currentUser => _auth.currentUser;

  Future<void> signOut() => _auth.signOut();

  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.ok(
        message: 'Email арқылы кіру сәтті.',
        uid: credential.user?.uid,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_authMessage(e));
    } catch (e) {
      return AuthResult.fail('Белгісіз қате: $e');
    }
  }

  Future<AuthResult> createWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.ok(
        message: 'Email арқылы тіркелу сәтті.',
        uid: credential.user?.uid,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_authMessage(e));
    } catch (e) {
      return AuthResult.fail('Белгісіз қате: $e');
    }
  }

  Future<AuthResult> signInOrRegisterWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final signInCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.ok(
        message: 'Email арқылы кіру сәтті.',
        uid: signInCredential.user?.uid,
      );
    } on FirebaseAuthException catch (signInError) {
      try {
        final createCredential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return AuthResult.ok(
          message: 'Email арқылы тіркелу сәтті.',
          uid: createCredential.user?.uid,
        );
      } on FirebaseAuthException catch (createError) {
        if (createError.code == 'email-already-in-use') {
          return AuthResult.fail(_authMessage(signInError));
        }
        return AuthResult.fail(_authMessage(createError));
      } catch (e) {
        return AuthResult.fail('Белгісіз қате: $e');
      }
    } catch (e) {
      return AuthResult.fail('Белгісіз қате: $e');
    }
  }

  Future<AuthResult> deleteClientAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      return AuthResult.fail("Қолданушы табылмады (Auth жоқ)");
    }

    final uid = user.uid;
    try {
      await user.delete();
      try {
        await _firestore.collection('users').doc(uid).delete();
      } catch (_) {
        // Auth delete success болса, Firestore cleanup сәтсіз болса да app flow-ды бұзбаймыз.
      }
      return AuthResult.ok(message: "Аккаунт өшірілді", uid: uid);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return AuthResult.fail(
          'Аккаунтты өшіру үшін қайта кіру қажет. Әзірге жүйеден шығу орындалады.',
        );
      }
      return AuthResult.fail(_authMessage(e));
    } catch (e) {
      return AuthResult.fail("Белгісіз қате: $e");
    }
  }

  // -------------------------
  // CLIENT PROFILE (Phone-only)
  // -------------------------
  Future<AuthResult> upsertClientProfile({
    required Map<String, dynamic> userData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return AuthResult.fail("Қолданушы табылмады (Auth жоқ)");
    }

    final payload = <String, dynamic>{
      ...userData,
      'uid': user.uid,
      'role': 'client',
      'phone': user.phoneNumber ?? userData['phone'],
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (!payload.containsKey('created_at')) {
      payload['created_at'] = FieldValue.serverTimestamp();
    }

    final publicPayload = <String, dynamic>{
      'displayName': _resolveDisplayName(payload),
      'avatarUrl': _asString(payload['avatarUrl']),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('users').doc(user.uid),
        payload,
        SetOptions(merge: true),
      );
      batch.set(
        _firestore.collection('public_profiles').doc(user.uid),
        publicPayload,
        SetOptions(merge: true),
      );
      await batch.commit();
      return AuthResult.ok(message: "Профиль сақталды", uid: user.uid);
    } on FirebaseException catch (e) {
      return AuthResult.fail(_firestoreMessage(e));
    } catch (e) {
      return AuthResult.fail("Белгісіз қате: $e");
    }
  }

  // -------------------------
  // WORKER PROFILE (Phone-first onboarding)
  // -------------------------
  Future<AuthResult> upsertWorkerProfile({
    required Map<String, dynamic> workerData,
    String? uid,
  }) async {
    final resolvedUid = uid ?? _auth.currentUser?.uid;
    if (resolvedUid == null || resolvedUid.isEmpty) {
      return AuthResult.fail("Қолданушы табылмады (Auth жоқ)");
    }

    final payload = <String, dynamic>{
      ...workerData,
      'uid': resolvedUid,
      'role': 'worker',
      'updated_at': FieldValue.serverTimestamp(),
    };

    payload.putIfAbsent('created_at', FieldValue.serverTimestamp);
    payload.putIfAbsent('createdAt', FieldValue.serverTimestamp);

    final workerRef = _firestore.collection('workers').doc(resolvedUid);
    final userRef = _firestore.collection('users').doc(resolvedUid);

    try {
      await _firestore.runTransaction((txn) async {
        final userSnap = await txn.get(userRef);
        if (userSnap.exists) {
          final existingRole = (userSnap.data()?['role'] ?? '').toString();
          if (existingRole.isNotEmpty && existingRole != 'worker') {
            throw const AuthProfileRoleMismatchException();
          }
        }

        txn.set(workerRef, payload, SetOptions(merge: true));
        txn.set(
          userRef,
          _workerUserPayload(
            uid: resolvedUid,
            phone: _auth.currentUser?.phoneNumber ?? workerData['phone'],
            fullName: _resolveWorkerDisplayName(payload),
            includeCreatedAt: !userSnap.exists,
          ),
          SetOptions(merge: true),
        );
      });
      return AuthResult.ok(message: "Шебер профилі сақталды", uid: resolvedUid);
    } on AuthProfileRoleMismatchException {
      return AuthResult.fail(
        "Бұл UID client ретінде тіркелген. Рөлді өзгертуге болмайды.",
      );
    } on FirebaseException catch (e) {
      return AuthResult.fail(_firestoreMessage(e));
    } catch (e) {
      return AuthResult.fail("Белгісіз қате: $e");
    }
  }

  // -------------------------
  // Message mappers
  // -------------------------
  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
        return "Firebase Auth-та Phone провайдері өшірулі.";
      case 'invalid-email':
        return "Email форматы қате.";
      case 'email-already-in-use':
        return "Бұл email бұрыннан тіркелген.";
      case 'user-not-found':
        return "Қолданушы табылмады.";
      case 'wrong-password':
      case 'invalid-credential':
        return "Email немесе құпиясөз қате.";
      case 'weak-password':
        return "Құпиясөз тым әлсіз (кемі 6 таңба).";
      case 'invalid-phone-number':
        return "Телефон нөмірі жарамсыз.";
      case 'invalid-verification-code':
        return "Код қате.";
      case 'session-expired':
      case 'code-expired':
        return "Кодтың уақыты өтті.";
      case 'too-many-requests':
        return "Көп сұраныс. Кейінірек қайталаңыз.";
      case 'network-request-failed':
        return "Интернет байланысы жоқ немесе әлсіз.";
      default:
        return "Auth қатесі: ${e.code} — ${e.message ?? ''}";
    }
  }

  String _firestoreMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return "Firestore: рұқсат жоқ (rules).";
      case 'unavailable':
        return "Firestore: сервис уақытша қолжетімсіз.";
      default:
        return "Firestore қатесі: ${e.code} — ${e.message ?? ''}";
    }
  }

  String _resolveDisplayName(Map<String, dynamic> payload) {
    final fullName = _asString(payload['fullName']);
    if (fullName.isNotEmpty) return fullName;

    final name = _asString(payload['name']);
    if (name.isNotEmpty) return name;

    final firstName = _asString(payload['firstName']);
    if (firstName.isNotEmpty) return firstName;

    return 'Клиент';
  }

  String _resolveWorkerDisplayName(Map<String, dynamic> payload) {
    final fullName = _asString(payload['fullName']);
    if (fullName.isNotEmpty) return fullName;

    final firstName = _asString(payload['firstName']);
    if (firstName.isNotEmpty) return firstName;

    final name = _asString(payload['name']);
    if (name.isNotEmpty) return name;

    return 'Шебер';
  }

  String _asString(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '';
    return text;
  }

  Map<String, dynamic> _workerUserPayload({
    required String uid,
    required dynamic phone,
    required String fullName,
    required bool includeCreatedAt,
  }) {
    final payload = <String, dynamic>{
      'uid': uid,
      'phone': phone,
      'name': fullName.isEmpty ? 'Шебер' : fullName,
      'role': 'worker',
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

class AuthProfileRoleMismatchException implements Exception {
  const AuthProfileRoleMismatchException();
}
