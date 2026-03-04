import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';

class WorkerChatDetailScreen extends StatefulWidget {
  final String clientName;
  const WorkerChatDetailScreen({super.key, required this.clientName});

  @override
  State<WorkerChatDetailScreen> createState() => _WorkerChatDetailScreenState();
}

class _WorkerChatDetailScreenState extends State<WorkerChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  
  // Жалған хабарламалар (Демо үшін)
  final List<Map<String, dynamic>> _messages = [
    {"text": "Сәлеметсіз бе! Кран ауыстыру қанша тұрады?", "isMe": false, "time": "10:00"},
    {"text": "Сәлем! 5000 теңге болады.", "isMe": true, "time": "10:05"},
    {"text": "Жақсы, қашан келе аласыз?", "isMe": false, "time": "10:10"},
  ];

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add({
          "text": _controller.text,
          "isMe": true,
          "time": "${DateTime.now().hour}:${DateTime.now().minute}",
        });
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Ашық сұр фон (Көз ауыртпайды)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: appBarBackButton(context),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.amber,
              radius: 18,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.clientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text("Онлайн", style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.call, color: Colors.black)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: Colors.black)),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ХАТТАР ТІЗІМІ
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['isMe'];
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFFFFD700) : Colors.white, // Сары (Шебер) және Ақ (Клиент)
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                          bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            msg['text'],
                            style: TextStyle(color: isMe ? Colors.black : Colors.black87, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg['time'],
                            style: TextStyle(color: isMe ? Colors.black54 : Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ХАТ ЖАЗУ ПОЛЕСІ
            Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(onPressed: () {}, icon: const Icon(LucideIcons.paperclip, color: Colors.grey)),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: "Хабарлама жазу...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xFFFFD700),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(LucideIcons.send, color: Colors.black, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
