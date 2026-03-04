import 'package:flutter/material.dart';

class WorkerBusinessCard extends StatelessWidget {
  final String name;
  final String city;
  final int exp;
  final bool hasBrigade;
  final String brigadeSize;
  final List<String> specs;
  final bool showShadow; // Option to disable shadow for lists

  const WorkerBusinessCard({
    super.key,
    required this.name,
    required this.city,
    required this.exp,
    required this.hasBrigade,
    required this.brigadeSize,
    required this.specs,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFE2A6),
            Color(0xFFFFA63C),
            Color(0xFFFF8A00),
          ],
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.85),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Icon(Icons.person, size: 32, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'Сіздің Атыңыз' : name,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              city.isEmpty ? 'Қалаңыз...' : city,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 18),
                ),
              ],
            ),
            // MIDDLE
            Row(
              children: [
                _buildBadge('ТӘЖІРИБЕ', '$exp жыл'),
                if (hasBrigade) ...[
                  const SizedBox(width: 12),
                  _buildBadge('БРИГАДА',
                      brigadeSize.isEmpty ? 'Бар' : '$brigadeSize адам'),
                ]
              ],
            ),
            // BOTTOM
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'МАМАНДЫҚТАР',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: specs.isNotEmpty
                      ? specs
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF8A00),
                                  ),
                                ),
                              ))
                          .toList()
                      : [
                          Text(
                            'Таңдаңыз...',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          )
                        ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}