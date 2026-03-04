import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/features/auth/models/auth_role.dart';

class AuthThemeData {
  final Color background;
  final Color surface;
  final Color primary;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color inputFill;
  final Color error;
  final Color success;
  final Color iconPrimary;
  final List<Color> accentGradient;
  final Color buttonPrimaryBg;
  final Color buttonPrimaryFg;
  final Color buttonSecondaryBg;
  final Color buttonSecondaryFg;

  const AuthThemeData({
    required this.background,
    required this.surface,
    required this.primary,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.inputFill,
    required this.error,
    required this.success,
    required this.iconPrimary,
    required this.accentGradient,
    required this.buttonPrimaryBg,
    required this.buttonPrimaryFg,
    required this.buttonSecondaryBg,
    required this.buttonSecondaryFg,
  });
}

AuthThemeData authThemeForRole(AuthRole role) {
  if (role == AuthRole.worker) {
    return const AuthThemeData(
      background: Color(0xFFF9FAFC),
      surface: Color(0xFFFEFEFF),
      primary: Color(0xFFFFD700),
      onPrimary: Color(0xFF111827),
      textPrimary: Color(0xFF111827),
      textSecondary: Color(0xFF6B7280),
      border: Color(0xFFE5E7EB),
      inputFill: Color(0xFFF9FAFB),
      error: AppColors.danger,
      success: AppColors.success,
      iconPrimary: Color(0xFF111827),
      accentGradient: [Color(0xFFFFF5D8), Color(0xFFFEFEFF)],
      buttonPrimaryBg: Color(0xFFFFD700),
      buttonPrimaryFg: Color(0xFF111827),
      buttonSecondaryBg: Color(0xFFFFF5D8),
      buttonSecondaryFg: Color(0xFF92400E),
    );
  }

  return const AuthThemeData(
    background: AppColors.bg,
    surface: AppColors.surface,
    primary: AppColors.gold,
    onPrimary: Colors.black,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    border: AppColors.border,
    inputFill: AppColors.surface2,
    error: AppColors.danger,
    success: AppColors.success,
    iconPrimary: AppColors.gold,
    accentGradient: [AppColors.surface2, AppColors.bg],
    buttonPrimaryBg: AppColors.gold,
    buttonPrimaryFg: Colors.black,
    buttonSecondaryBg: AppColors.surface2,
    buttonSecondaryFg: AppColors.gold,
  );
}
