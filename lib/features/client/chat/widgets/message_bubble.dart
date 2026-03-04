import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;

  const MessageBubble({super.key, required this.text, required this.time, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          // Менің хабарламам: Қара сұр + Сары жиек (Жұмысшы стилі)
          // Олардың хабарламасы: Ашық сұр
          color: isMe ? const Color(0xFF1A1A1A) : const Color(0xFF2C2C2C),
          border: isMe ? Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)) : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 14, color: Color(0xFFFFD700)),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}