// lib/features/auth/models/auth_user.dart
class AuthUser {
  final String id;
  final String phone;
  final String? role; // 'worker' немесе 'client'
  final String? name;

  AuthUser({
    required this.id,
    required this.phone,
    this.role,
    this.name,
  });
}
