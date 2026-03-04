import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

class PhoneCodeRequestResult {
  final bool codeSent;
  final bool autoVerified;
  final String? verificationId;
  final int? resendToken;
  final String? errorMessage;

  const PhoneCodeRequestResult._({
    required this.codeSent,
    required this.autoVerified,
    this.verificationId,
    this.resendToken,
    this.errorMessage,
  });

  factory PhoneCodeRequestResult.codeSent({
    required String verificationId,
    int? resendToken,
  }) {
    return PhoneCodeRequestResult._(
      codeSent: true,
      autoVerified: false,
      verificationId: verificationId,
      resendToken: resendToken,
    );
  }

  factory PhoneCodeRequestResult.autoVerified() {
    return const PhoneCodeRequestResult._(codeSent: false, autoVerified: true);
  }

  factory PhoneCodeRequestResult.error(String message) {
    return PhoneCodeRequestResult._(
      codeSent: false,
      autoVerified: false,
      errorMessage: message,
    );
  }
}

class PhoneAuthService {
  final FirebaseAuth _auth;

  PhoneAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  Future<void> _authenticateWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      try {
        await currentUser.linkWithCredential(credential);
        return;
      } on FirebaseAuthException catch (e) {
        // If this phone is already linked to another account, sign in to it.
        if (e.code != 'credential-already-in-use' &&
            e.code != 'provider-already-linked') {
          rethrow;
        }
      }
    }

    await _auth.signInWithCredential(credential);
  }

  Future<PhoneCodeRequestResult> requestCode({
    required String phoneNumber,
    int? forceResendingToken,
  }) async {
    final completer = Completer<PhoneCodeRequestResult>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _authenticateWithPhoneCredential(credential);
            if (!completer.isCompleted) {
              completer.complete(PhoneCodeRequestResult.autoVerified());
            }
          } on FirebaseAuthException catch (e) {
            if (!completer.isCompleted) {
              completer.complete(PhoneCodeRequestResult.error(mapAuthError(e)));
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.complete(
                PhoneCodeRequestResult.error('Белгісіз қате: $e'),
              );
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.complete(PhoneCodeRequestResult.error(mapAuthError(e)));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(
              PhoneCodeRequestResult.codeSent(
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } on FirebaseAuthException catch (e) {
      if (!completer.isCompleted) {
        completer.complete(PhoneCodeRequestResult.error(mapAuthError(e)));
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.complete(PhoneCodeRequestResult.error('Белгісіз қате: $e'));
      }
    }

    return completer.future;
  }

  Future<String?> verifyCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _authenticateWithPhoneCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      return mapAuthError(e);
    } catch (e) {
      return 'Белгісіз қате: $e';
    }
  }

  String mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
      case 'invalid-code':
        return 'Код қате';
      case 'session-expired':
      case 'code-expired':
      case 'expired-code':
        return 'Кодтың уақыты өтті, қайта жіберіңіз';
      case 'too-many-requests':
        return 'Көп сұраныс. Кейінірек қайталаңыз';
      case 'network-request-failed':
        return 'Интернет жоқ немесе байланыс әлсіз';
      case 'invalid-phone-number':
        return 'Телефон нөмірі жарамсыз';
      case 'operation-not-allowed':
        return 'Phone auth Firebase-та қосылмаған';
      default:
        return e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Аутентификация қатесі: ${e.code}';
    }
  }
}
