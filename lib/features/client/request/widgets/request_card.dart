import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/widgets/safe_network_image.dart';

class RequestCard extends StatelessWidget {
  final String title;
  final String category;
  final String price;
  final String location;
  final String date;
  final String imageUrl;

  const RequestCard({
    super.key,
    required this.title,
    required this.category,
    required this.price,
    required this.location,
    required this.date,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    const kCardBg = Color(0xFF1A1A1A);
    const kGold = Color(0xFFFFD700);

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SafeNetworkImage(
              url: imageUrl,
              width: 86,
              height: 86,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // CATEGORY + MENU
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.more_vert,
                        color: Colors.white.withValues(alpha: 0.3), size: 16),
                  ],
                ),

                const SizedBox(height: 6),

                // TITLE
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // PRICE
                Text(
                  price,
                  style: const TextStyle(
                    color: kGold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                // LOCATION + DOT + TIME
                Row(
                  children: [
                    Icon(CupertinoIcons.location_solid,
                        size: 10, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),

                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: CircleAvatar(
                          radius: 1.5,
                          backgroundColor: Colors.white.withValues(alpha: 0.2)),
                    ),

                    Icon(CupertinoIcons.time,
                        size: 10, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),

                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
