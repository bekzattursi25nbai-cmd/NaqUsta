import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:kuryl_kz/core/services/auth_service.dart';

class WorkerAuthService {
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  WorkerAuthService({FirebaseAuth? auth, FirebaseStorage? storage})
    : _auth = auth ?? FirebaseAuth.instance,
      _storage = storage ?? FirebaseStorage.instance;

  Future<bool> startPhoneAuth(String phone) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      debugPrint(
        'WorkerAuthService.startPhoneAuth blocked. Auth session required for $phone',
      );
      return false;
    }

    final hasPhone = (user.phoneNumber ?? '').trim().isNotEmpty;
    final hasEmail = (user.email ?? '').trim().isNotEmpty;
    if (!hasPhone && !hasEmail) {
      debugPrint(
        'WorkerAuthService.startPhoneAuth blocked. No phone/email identity for $phone',
      );
      return false;
    }
    return true;
  }

  Future<AuthResult> ensureWorkerSession({required String phoneDigits}) async {
    final existingUser = _auth.currentUser;
    if (existingUser == null) {
      return AuthResult.fail('Алдымен телефон арқылы OTP-пен кіріңіз.');
    }
    if (existingUser.isAnonymous) {
      return AuthResult.fail(
        'Анонимді сессия қолдау таппайды. OTP-пен кіріңіз.',
      );
    }

    final phone = existingUser.phoneNumber ?? '';
    if (phone.isEmpty) {
      final email = (existingUser.email ?? '').trim();
      if (email.isNotEmpty) {
        return AuthResult.ok(message: 'Session ready', uid: existingUser.uid);
      }
      return AuthResult.fail('Бұл аккаунт Phone OTP немесе Email арқылы расталмаған.');
    }

    final normalizedDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalizedDigits.isNotEmpty &&
        !normalizedDigits.endsWith(
          phoneDigits.replaceAll(RegExp(r'[^0-9]'), ''),
        )) {
      return AuthResult.fail('Кіру телефоны мен тіркелу телефоны сәйкес емес.');
    }

    return AuthResult.ok(message: 'Session ready', uid: existingUser.uid);
  }

  Future<String?> uploadAvatar({
    required String uid,
    required String localPath,
  }) async {
    final path = localPath.trim();
    if (path.isEmpty) return null;

    try {
      final file = File(path);
      if (!file.existsSync()) return null;

      final ext = _fileExtension(path);
      final ref = _storage.ref().child(
        'uploads/$uid/images/avatars/worker_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );

      await ref.putFile(file, SettableMetadata(contentType: 'image/$ext'));
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  String _fileExtension(String path) {
    final normalized = path.toLowerCase();
    if (normalized.endsWith('.png')) return 'png';
    if (normalized.endsWith('.webp')) return 'webp';
    return 'jpeg';
  }
}
