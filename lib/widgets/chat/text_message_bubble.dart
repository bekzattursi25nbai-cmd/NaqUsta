// lib/widgets/chat/text_message_bubble.dart
import 'package:flutter/material.dart';

class TextMessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String? timeLabel;

  const TextMessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final background = isMe ? Colors.black : Colors.grey.shade200;
    final foreground = isMe ? Colors.white : Colors.black87;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(color: foreground, fontSize: 14),
            ),
            if (timeLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                timeLabel!,
                style: TextStyle(
                  color: foreground.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
