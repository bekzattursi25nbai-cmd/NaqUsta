import 'package:flutter/material.dart';

class BrigadeToggle extends StatelessWidget {
  final bool value;
  final Function(bool) onChanged;

  const BrigadeToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFFFF9C4) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? const Color(0xFFFFD700) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                if (value)
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.2),
                    blurRadius: 8,
                  )
              ],
            ),
            child: Icon(
              Icons.groups_rounded,
              color: value ? Colors.orange : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Бригадаңыз бар ма?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  value ? "Иә, командамен жұмыс істеймін" : "Жоқ, жеке шебермін",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFFFD700),
          ),
        ],
      ),
    );
  }
}
