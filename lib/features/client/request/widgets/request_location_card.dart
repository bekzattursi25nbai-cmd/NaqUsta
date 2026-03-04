// lib/features/request/widgets/request_location_card.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RequestLocationCard extends StatelessWidget {
  final String address;
  final VoidCallback onTap;

  const RequestLocationCard({
    super.key,
    required this.address,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const kCardBg = Color(0xFF111111);
    const kBorder = Color(0xFF333333);
    const kGold = Color(0xFFFFD700);

    final bool hasAddress = address.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            "МЕКЕН-ЖАЙЫ",
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),

        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: hasAddress ? kGold : kBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.location_solid,
                  color: hasAddress ? kGold : Colors.grey[600],
                  size: 22,
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: hasAddress
                      ? Text(
                          address,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : const Text(
                          "Қала, Аудан, Ауыл таңдау...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),

                Icon(
                  CupertinoIcons.chevron_down,
                  color: Colors.grey[600],
                  size: 18,
                )
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}
