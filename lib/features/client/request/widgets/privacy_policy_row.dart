import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kuryl_kz/core/widgets/safe_button_text.dart';

class PrivacyPolicyRow extends StatelessWidget {
  final VoidCallback? onTap;

  const PrivacyPolicyRow({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(
          CupertinoIcons.shield_fill,
          size: 14,
          color: Colors.grey[600],
        ),
        label: SafeButtonText(
          "Құпиялылық саясатымен келісемін",
          maxLines: 2,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            decoration: TextDecoration.underline,
          ),
        ),
        style: TextButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
        ),
      ),
    );
  }
}
