import 'package:flutter/material.dart';

class WorkerCategoryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final IconData? icon;
  final VoidCallback onTap;

  const WorkerCategoryChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const kGold = Color(0xFFFFD700);
    const kInputBg = Color(0xFF1A1A1A);
    const kBorder = Color(0xFF333333);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? kGold : kInputBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isActive ? kGold : kBorder),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.black : const Color(0xFF888888),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : const Color(0xFF888888),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
