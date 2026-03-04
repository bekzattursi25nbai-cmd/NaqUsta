import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClientInputField extends StatelessWidget {
  final String? label;
  final String hint;
  final IconData icon;
  final String initialValue;
  final Function(String) onChanged;
  final TextInputType keyboard;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;
  final EdgeInsets? scrollPadding;

  // ЖАҢАДАН ҚОСЫЛҒАН ПАРАМЕТРЛЕР 👇
  final bool isPassword;
  final Widget? suffixIcon;

  const ClientInputField({
    super.key,
    this.label,
    required this.hint,
    required this.icon,
    required this.initialValue,
    required this.onChanged,
    this.keyboard = TextInputType.text,
    // Default мәндер (Қате шықпас үшін)
    this.isPassword = false,
    this.suffixIcon,
    this.prefixText,
    this.inputFormatters,
    this.scrollPadding,
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
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          keyboardType: keyboard,
          obscureText: isPassword, // 🔑 Құпия сөзді жасыру
          inputFormatters: inputFormatters,
          scrollPadding: scrollPadding ?? const EdgeInsets.all(20),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixStyle: const TextStyle(color: Color(0xFF9E9E9E), fontWeight: FontWeight.bold),
            hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E)),
            suffixIcon: suffixIcon, // 👁️ Көз белгішесі осында тұрады
            contentPadding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFF1A1A1A), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
