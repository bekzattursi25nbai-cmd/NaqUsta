// lib/features/auth/widgets/input_field.dart
import 'package:flutter/material.dart';

class AuthInputField extends StatelessWidget {
  final String? label;
  final String hint;
  final IconData? icon;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  const AuthInputField({
    super.key,
    this.label,
    required this.hint,
    this.icon,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              label!,
              style: const TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
                letterSpacing: 0.5,
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF9E9E9E), size: 20)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 16.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide:
                  const BorderSide(color: Color(0xFFE0E0E0), width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide:
                  const BorderSide(color: Color(0xFFE0E0E0), width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: const BorderSide(color: Colors.amber, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}
