import 'package:flutter/material.dart';

class SafeButtonText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign textAlign;

  const SafeButtonText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: style,
    );
  }
}
