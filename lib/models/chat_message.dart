// lib/models/chat_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatMessageType { text, voice, image, system }

ChatMessageType _typeFromString(String? value) {
  switch (value) {
    case 'system':
      return ChatMessageType.system;
    case 'voice':
      return ChatMessageType.voice;
    case 'image':
      return ChatMessageType.image;
    case 'text':
    default:
      return ChatMessageType.text;
  }
}

String _typeToString(ChatMessageType type) {
  switch (type) {
    case ChatMessageType.system:
      return 'system';
    case ChatMessageType.voice:
      return 'voice';
    case ChatMessageType.image:
      return 'image';
    case ChatMessageType.text:
      return 'text';
  }
}

class ChatMessage {
  final String id;
  final ChatMessageType type;
  final String? text;
  final String? audioUrl;
  final List<String>? imageUrls;
  final String senderId;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.type,
    required this.senderId,
    this.text,
    this.audioUrl,
    this.imageUrls,
    this.createdAt,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final createdAt = data['createdAt'];

    return ChatMessage(
      id: doc.id,
      type: _typeFromString(data['type'] as String?),
      text: data['text'] as String?,
      audioUrl: data['audioUrl'] as String?,
      imageUrls: (data['imageUrls'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      senderId: (data['senderId'] as String?) ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': _typeToString(type),
      'text': text,
      'audioUrl': audioUrl,
      'imageUrls': imageUrls,
      'senderId': senderId,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
