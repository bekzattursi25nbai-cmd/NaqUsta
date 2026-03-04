// lib/features/auth/widgets/auth_button.dart
import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/widgets/safe_button_text.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: SafeButtonText(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
