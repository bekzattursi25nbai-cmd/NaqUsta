// lib/features/auth/widgets/otp_field.dart
import 'package:flutter/material.dart';

class OtpField extends StatelessWidget {
  final int length;
  final ValueChanged<String> onChanged;

  const OtpField({
    super.key,
    this.length = 4,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controllers =
        List.generate(length, (_) => TextEditingController());

    void updateCode() {
      final code = controllers.map((c) => c.text).join();
      onChanged(code);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        length,
        (index) => SizedBox(
          width: 56,
          child: TextField(
            controller: controllers[index],
            maxLength: 1,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            onChanged: (_) => updateCode(),
          ),
        ),
      ),
    );
  }
}
