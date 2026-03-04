import 'package:kuryl_kz/features/auth/models/auth_role.dart';

class RoleSelectionCache {
  RoleSelectionCache._();

  static final RoleSelectionCache instance = RoleSelectionCache._();

  AuthRole? _selectedRole;

  AuthRole? get selectedRole => _selectedRole;

  void setRole(AuthRole role) {
    _selectedRole = role;
  }

  void clear() {
    _selectedRole = null;
  }
}
