import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/widgets/safe_button_text.dart';

class WorkerSuccessScreen extends StatelessWidget {
  final String userName;

  const WorkerSuccessScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 24),
            Text(
              "Құттықтаймыз, $userName!",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Тіркелу сәтті аяқталды.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const SafeButtonText(
                "Жұмысқа кірісу",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
