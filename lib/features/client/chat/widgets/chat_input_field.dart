import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';

class ChatInputField extends StatefulWidget {
  final Function(String) onSend;

  const ChatInputField({super.key, required this.onSend});

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();

  void _send() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSend(_controller.text.trim());
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.paperclip, color: AppColors.textMuted),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _controller,
                style: AppTypography.body,
                decoration: const InputDecoration(
                  hintText: "Хабарлама...",
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _send,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
