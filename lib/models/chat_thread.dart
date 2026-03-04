import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  final String id;
  final String? orderId;
  final String clientId;
  final String workerId;
  final String? clientName;
  final String? clientAvatarUrl;
  final String? workerName;
  final String? workerAvatarUrl;
  final String? lastMessage;
  final String? lastMessageType;
  final String? lastSenderId;
  final DateTime? lastMessageAt;
  final DateTime? updatedAt;

  const ChatThread({
    required this.id,
    this.orderId,
    required this.clientId,
    required this.workerId,
    this.clientName,
    this.clientAvatarUrl,
    this.workerName,
    this.workerAvatarUrl,
    this.lastMessage,
    this.lastMessageType,
    this.lastSenderId,
    this.lastMessageAt,
    this.updatedAt,
  });

  factory ChatThread.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final lastMessageAt = data['lastMessageAt'];
    final updatedAt = data['updatedAt'];

    return ChatThread(
      id: doc.id,
      orderId: data['orderId'] as String?,
      clientId: (data['clientId'] as String?) ?? '',
      workerId: (data['workerId'] as String?) ?? '',
      clientName: data['clientName'] as String?,
      clientAvatarUrl: data['clientAvatarUrl'] as String?,
      workerName: data['workerName'] as String?,
      workerAvatarUrl: data['workerAvatarUrl'] as String?,
      lastMessage: data['lastMessage'] as String?,
      lastMessageType: data['lastMessageType'] as String?,
      lastSenderId: data['lastSenderId'] as String?,
      lastMessageAt: lastMessageAt is Timestamp ? lastMessageAt.toDate() : null,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }
}
