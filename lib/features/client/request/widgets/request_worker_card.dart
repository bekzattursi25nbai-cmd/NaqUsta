import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/widgets/safe_network_image.dart';

class RequestWorkerCard extends StatelessWidget {
  final String title;
  final String category;
  final String price;
  final String location;
  final String date;
  final String distance;
  final String responses;
  final String imageUrl;
  final VoidCallback? onTap;

  const RequestWorkerCard({
    super.key,
    required this.title,
    required this.category,
    required this.price,
    required this.location,
    required this.date,
    required this.distance,
    required this.responses,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const kBgColor = Color(0xFF111111);
    const kBorderColor = Color(0xFF222222);
    const kGold = Color(0xFFFFD700);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // -------------------------------
          // TOP SECTION
          // -------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[900],
                  child: SafeNetworkImage(
                    url: imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // TEXT AREA
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CATEGORY & DATE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // TITLE
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // PRICE
                    Text(
                      price,
                      style: const TextStyle(
                        color: kGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // DISTANCE + RESPONSES
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222222),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF333333),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.navigation,
                                  size: 10, color: kGold),
                              const SizedBox(width: 4),
                              Text(
                                distance,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        Text(
                          "$responses ұсыныс",
                          style: TextStyle(
                            color: Colors.grey[500],
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

          const SizedBox(height: 16),

          // -------------------------------
          // ACTION BUTTON
          // -------------------------------
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: const Center(
                child: Text(
                  "Қабылдау",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
