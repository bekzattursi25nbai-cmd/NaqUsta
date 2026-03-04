// lib/features/request/widgets/request_input_field.dart

import 'package:flutter/material.dart';

class RequestInputField extends StatelessWidget {
  final String label;
  final String placeholder;
  final IconData icon;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final String initialValue;
  final bool enabled;

  const RequestInputField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.initialValue = "",
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    const kCardBg = Color(0xFF111111);
    const kBorder = Color(0xFF333333);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LABEL
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),

        // FIELD
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kBorder),
              ),
              child: TextField(
                enabled: enabled,
                controller: TextEditingController(text: initialValue),
                keyboardType: keyboardType,
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.grey[700],
                  fontSize: 16,
                ),
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: const TextStyle(color: Color(0xFF444444)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(56, 16, 16, 16),
                ),
              ),
            ),

            // LEFT ICON
            Positioned(
              left: 20,
              top: 16,
              child: Icon(
                icon,
                color: Colors.grey[600],
                size: 18,
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}
