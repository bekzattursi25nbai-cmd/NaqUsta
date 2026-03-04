import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/core/widgets/app_loading.dart';
import 'package:kuryl_kz/core/widgets/safe_network_image.dart';
import 'package:kuryl_kz/models/chat_thread.dart';
import 'package:kuryl_kz/screens/chat/chat_screen.dart';
import 'package:kuryl_kz/services/chat_service.dart';

class WorkerChatListScreen extends StatelessWidget {
  const WorkerChatListScreen({super.key});

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      final hh = time.hour.toString().padLeft(2, '0');
      final mm = time.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    if (diff.inDays == 1) {
      return 'Кеше';
    }
    final dd = time.day.toString().padLeft(2, '0');
    final mm = time.month.toString().padLeft(2, '0');
    return '$dd.$mm';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFC),
        body: Center(child: Text("Алдымен жүйеге кіріңіз")),
      );
    }

    final chatService = ChatService();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: appBarBackButton(context),
        title: const Text(
          "Хабарламалар",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: StreamBuilder<List<ChatThread>>(
          stream: chatService.streamWorkerChats(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Қате: ${snapshot.error}"));
            }
            if (!snapshot.hasData) {
              return const Center(
                child: AppLoadingIndicator(
                  size: 26,
                  strokeWidth: 2.5,
                  color: Colors.amber,
                ),
              );
            }

            final chats = snapshot.data!;
            if (chats.isEmpty) {
              return const Center(
                child: Text(
                  "Әзірге чат жоқ",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildChatItem(context, chats[index], user.uid);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    ChatThread chat,
    String currentId,
  ) {
    final name = (chat.clientName ?? '').trim().isNotEmpty
        ? chat.clientName!.trim()
        : "Клиент";
    final lastMessage = (chat.lastMessage ?? '').trim().isNotEmpty
        ? chat.lastMessage!.trim()
        : "Хабарлама жоқ";
    final timeLabel = _formatTime(chat.lastMessageAt ?? chat.updatedAt);
    final avatarUrl = chat.clientAvatarUrl;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chat.id,
              orderId: chat.orderId,
              clientId: chat.clientId,
              workerId: chat.workerId,
              currentUserId: currentId,
              peerUserId: chat.clientId,
              peerName: name,
              peerAvatarUrl: avatarUrl,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[200],
              child: (avatarUrl != null && avatarUrl.trim().isNotEmpty)
                  ? ClipOval(
                      child: SafeNetworkImage(
                        url: avatarUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
