import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/core/widgets/safe_network_image.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_field.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatDetailScreen({super.key, required this.chat});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  List<MessageModel> messages = [
    MessageModel(id: 1, text: "Сәлеметсіз бе! Крыша жабу керек еді.", time: "14:30", isMe: true),
    MessageModel(id: 2, text: "Сәлем! Әрине. Квадраты қанша болады?", time: "14:32", isMe: false),
    MessageModel(id: 3, text: "Шамамен 120 квадрат. Материал өзімнен.", time: "14:33", isMe: true),
    MessageModel(id: 4, text: "Жақсы. Бағасы 450 000 теңге болады. Ертең бастай аламыз.", time: "14:35", isMe: false),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend(String text) {
    setState(() {
      messages.add(MessageModel(
        id: DateTime.now().millisecondsSinceEpoch,
        text: text,
        time: "${DateTime.now().hour}:${DateTime.now().minute}",
        isMe: true,
      ));
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.95),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const AppBackButton(),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.surface2,
                    child: ClipOval(
                      child: SafeNetworkImage(
                        url: widget.chat.img,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.chat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body,
                        ),
                        Text(widget.chat.online ? "Online" : "Offline",
                            style: AppTypography.caption.copyWith(color: AppColors.gold)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(CupertinoIcons.phone, color: AppColors.textPrimary), onPressed: () {}),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return MessageBubble(text: msg.text, time: msg.time, isMe: msg.isMe);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: ChatInputField(onSend: _handleSend),
            ),
          ],
        ),
      ),
    );
  }
}
