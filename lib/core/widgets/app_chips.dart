import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';

class AppChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idleColor = isDark ? AppColors.surface2 : const Color(0xFFFFFBED);
    final idleBorder = isDark ? AppColors.border : const Color(0xFFE6E1D8);
    final idleText = isDark ? AppColors.textSecondary : const Color(0xFF6E6557);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : idleColor,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: selected ? AppColors.goldDeep : idleBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : idleText,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class AppTagChip extends StatelessWidget {
  final String label;

  const AppTagChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.surface2 : const Color(0xFFFFFBED);
    final border = isDark ? AppColors.border : const Color(0xFFE6E1D8);
    final textColor = isDark
        ? AppColors.textSecondary
        : const Color(0xFF6E6557);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
