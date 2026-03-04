import 'package:flutter/material.dart';

class AppColors {
  static const Color bg = Color(0xFF0B0B0F);
  static const Color surface = Color(0xFF121218);
  static const Color surface2 = Color(0xFF181820);
  static const Color card = Color(0xFF1B1B24);
  static const Color border = Color(0xFF262633);
  static const Color borderSoft = Color(0x1AFFFFFF);

  static const Color gold = Color(0xFFFFD700);
  static const Color goldSoft = Color(0x33FFD700);
  static const Color goldDeep = Color(0xFFE6C200);

  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFB7B7C2);
  static const Color textMuted = Color(0xFF8B8B98);

  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF5A524);
  static const Color danger = Color(0xFFFF5A5F);
}

class AppRadii {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> glow = [
    BoxShadow(
      color: Color(0x33FFD700),
      blurRadius: 28,
      offset: Offset(0, 6),
    ),
  ];
}

class AppMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 360);
}

class AppTypography {
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyMuted = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static TextTheme textTheme = const TextTheme(
    headlineLarge: h1,
    headlineMedium: h2,
    headlineSmall: h3,
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    bodyMedium: body,
    bodySmall: caption,
  );
}
