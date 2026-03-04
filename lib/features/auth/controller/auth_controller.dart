// lib/features/auth/controller/auth_controller.dart
class AuthController {
  String? selectedRole; // 'worker' немесе 'client'
  String phone = '';
  String? otpCode;

  void setRole(String role) {
    selectedRole = role;
  }

  void setPhone(String value) {
    phone = value;
  }

  void setOtp(String code) {
    otpCode = code;
  }

  // Мұнда кейін реальный backend логиканы қосасың
  Future<void> sendOtp() async {
    // TODO: API шақыру
  }

  Future<bool> verifyOtp() async {
    // TODO: API тексеру
    return true;
  }
}
