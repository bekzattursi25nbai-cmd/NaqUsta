import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class RequestImagePicker extends StatelessWidget {
  final List<File> selectedImages; // 1 фото емес, тізім (List)
  final VoidCallback onTap;
  final Function(int) onRemove;    // Суретті өшіру функциясы

  const RequestImagePicker({
    super.key,
    required this.selectedImages,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    const kCardBg = Color(0xFF111111);
    const kBorder = Color(0xFF333333);
    const kGold = Color(0xFFFFD700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                "ФОТОЛАР (МІНДЕТТІ ЕМЕС)",
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            if (selectedImages.isNotEmpty)
              Text(
                "${selectedImages.length} фото таңдалды",
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              )
          ],
        ),

        // 1. ЕГЕР СУРЕТТЕР БАР БОЛСА -> Тізім (Horizontal List)
        if (selectedImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              // +1 (Қосу батырмасы үшін)
              itemCount: selectedImages.length + 1, 
              itemBuilder: (context, index) {
                // Ең соңына "Тағы қосу" батырмасын қоямыз
                if (index == selectedImages.length) {
                  return GestureDetector(
                    onTap: onTap,
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: kCardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder),
                      ),
                      child: Center(
                        child: Icon(CupertinoIcons.add, color: Colors.grey[600], size: 30),
                      ),
                    ),
                  );
                }

                // Суретті көрсету
                return Stack(
                  children: [
                    Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kGold.withValues(alpha: 0.5)),
                        image: DecorationImage(
                          image: FileImage(selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Өшіру батырмасы (X)
                    Positioned(
                      top: 4,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => onRemove(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        
        // 2. ЕГЕР СУРЕТ ЖОҚ БОЛСА -> Үлкен батырма
        else
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.camera_fill, color: Colors.grey[800], size: 40),
                  const SizedBox(height: 8),
                  Text(
                    "Суреттер жүктеу",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        const SizedBox(height: 32),
      ],
    );
  }
}