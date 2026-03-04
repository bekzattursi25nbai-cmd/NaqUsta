// lib/features/request/widgets/request_material_toggle.dart

import 'package:flutter/material.dart';

class RequestMaterialToggle extends StatelessWidget {
  final String selected; // "worker" or "client"
  final Function(String) onChanged;

  const RequestMaterialToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const kCardBg = Color(0xFF111111);
    const kBorder = Color(0xFF333333);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LABEL
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            "МАТЕРИАЛ КІМНЕН?",
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),

        // TOGGLE CONTAINER
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              // ШЕБЕРДЕН
              _buildButton(
                label: "Шеберден",
                value: "worker",
                selected: selected,
                onTap: onChanged,
              ),
              const SizedBox(width: 8),

              // МЕНЕН
              _buildButton(
                label: "Менен",
                value: "client",
                selected: selected,
                onTap: onChanged,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // -----------------------------
  // BUTTON BUILDER
  // -----------------------------
  Widget _buildButton({
    required String label,
    required String value,
    required String selected,
    required Function(String) onTap,
  }) {
    const kGold = Color(0xFFFFD700);

    final bool isActive = selected == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? kGold : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: kGold.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
