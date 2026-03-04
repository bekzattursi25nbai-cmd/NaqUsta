import 'package:flutter/material.dart';

class RequestPriceField extends StatelessWidget {
  final bool isNegotiable;
  final Function(bool) onToggleNegotiable;
  final String price;
  final Function(String) onPriceChanged;

  const RequestPriceField({
    super.key,
    required this.isNegotiable,
    required this.onToggleNegotiable,
    required this.price,
    required this.onPriceChanged,
  });

  @override
  Widget build(BuildContext context) {
    const kCardBg = Color(0xFF111111);
    const kBorder = Color(0xFF333333);
    const kGold = Color(0xFFFFD700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LABEL
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            "БАҒАСЫ",
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),

        // PRICE CARD
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              // PRICE INPUT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    enabled: !isNegotiable,
                    keyboardType: TextInputType.number,
                    onChanged: onPriceChanged,
                    style: TextStyle(
                      color: isNegotiable ? Colors.grey[700] : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: "0",
                      hintStyle:
                          TextStyle(color: Colors.grey[800], fontSize: 20),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              // DIVIDER
              Container(width: 1, height: 40, color: const Color(0xFF333333)),
              const SizedBox(width: 8),

              // NEGOTIABLE BUTTON
              GestureDetector(
                onTap: () => onToggleNegotiable(!isNegotiable),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isNegotiable ? kGold : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: isNegotiable
                        ? [
                            BoxShadow(
                              color: kGold.withValues(alpha: 0.2),
                              blurRadius: 10,
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    "Келісімді",
                    style: TextStyle(
                      color: isNegotiable ? Colors.black : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}
