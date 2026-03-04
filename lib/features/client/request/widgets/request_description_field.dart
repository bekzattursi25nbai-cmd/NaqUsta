import 'package:flutter/material.dart';

class RequestDescriptionField extends StatelessWidget {
  final String value;
  final Function(String) onChanged;

  const RequestDescriptionField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const kCardBg = Color(0xFF111111);
    const kBorder = Color(0xFF333333);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            "СИПАТТАМАСЫ",
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kBorder),
          ),
          child: TextField(
            maxLines: 5,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              hintText: "Не істеу керек? Толық жазыңыз...",
              hintStyle: TextStyle(color: Color(0xFF444444)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}
