// lib/features/worker/registration/widgets/skill_card.dart
import 'package:flutter/material.dart';

class SkillCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SkillCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.amber.shade400 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.amber : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.black : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }
}
