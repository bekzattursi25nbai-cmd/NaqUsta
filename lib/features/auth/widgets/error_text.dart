// lib/features/auth/widgets/error_text.dart
import 'package:flutter/material.dart';

class ErrorText extends StatelessWidget {
  final String? message;

  const ErrorText({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        message!,
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
