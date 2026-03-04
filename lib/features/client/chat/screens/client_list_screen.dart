import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kuryl_kz/core/theme/app_tokens.dart';
import 'package:kuryl_kz/core/widgets/app_loading.dart';
import 'package:kuryl_kz/core/widgets/safe_network_image.dart';
import 'package:kuryl_kz/models/chat_thread.dart';
import 'package:kuryl_kz/screens/chat/chat_screen.dart';
import 'package:kuryl_kz/services/chat_service.dart';

class ClientListScreen extends StatelessWidget {
  const ClientListScreen({super.key});

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      final hh = time.hour.toString().padLeft(2, '0');
      final mm = time.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    if (diff.inDays == 1) return 'Кеше';

    final dd = time.day.toString().padLeft(2, '0');
    final mm = time.month.toString().padLeft(2, '0');
    return '$dd.$mm';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Text('Алдымен жүйеге кіріңіз', style: AppTypography.body),
        ),
      );
    }

    final chatService = ChatService();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Хабарламалар', style: AppTypography.h2),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: const Icon(
                          LucideIcons.messageCircle,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<ChatThread>>(
                    stream: chatService.streamClientChats(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Қате: ${snapshot.error}',
                            style: AppTypography.bodyMuted,
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: AppLoadingIndicator(
                            size: 28,
                            strokeWidth: 2.6,
                            color: AppColors.gold,
                          ),
                        );
                      }

                      final chats = snapshot.data!;
                      if (chats.isEmpty) {
                        return const Center(
                          child: Text(
                            'Әзірге чат жоқ',
                            style: AppTypography.bodyMuted,
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: chats.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _ChatTile(
                            chat: chats[index],
                            currentUserId: user.uid,
                            timeLabel: _formatTime(
                              chats[index].lastMessageAt ??
                                  chats[index].updatedAt,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.chat,
    required this.currentUserId,
    required this.timeLabel,
  });

  final ChatThread chat;
  final String currentUserId;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final name = (chat.workerName ?? '').trim().isNotEmpty
        ? chat.workerName!.trim()
        : 'Шебер';
    final avatarUrl = (chat.workerAvatarUrl ?? '').trim();
    final lastMessage = (chat.lastMessage ?? '').trim().isEmpty
        ? 'Хабарлама жоқ'
        : chat.lastMessage!.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chat.id,
              orderId: chat.orderId,
              clientId: chat.clientId,
              workerId: chat.workerId,
              currentUserId: currentUserId,
              peerUserId: chat.workerId,
              peerName: name,
              peerAvatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surface2,
              child: avatarUrl.isEmpty
                  ? Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : ClipOval(
                      child: SafeNetworkImage(
                        url: avatarUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(timeLabel, style: AppTypography.caption),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption,
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
