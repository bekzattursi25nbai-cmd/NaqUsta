import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WorkerInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final int maxLines;
  final TextAlign textAlign;
  final Function(String)? onChanged;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;

  const WorkerInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.prefixText,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textAlign: textAlign,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        decoration: InputDecoration(
          hintText: hintText,
          prefixText: prefixText,
          prefixStyle: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.normal),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF9CA3AF)) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
} 