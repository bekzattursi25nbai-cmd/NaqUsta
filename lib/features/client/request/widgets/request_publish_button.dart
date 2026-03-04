import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/widgets/safe_button_text.dart';

class RequestPublishButton extends StatelessWidget {
  final VoidCallback onTap;

  const RequestPublishButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const kGold = Color(0xFFFFD700);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black,
            Colors.black87,
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: kGold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            elevation: 0,
          ),
          child: const SafeButtonText(
            "Жариялау",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
