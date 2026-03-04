// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static String buildChatId(String clientId, String workerId) {
    final ids = [clientId, workerId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  CollectionReference<Map<String, dynamic>> _messagesRef(String chatId) {
    return _firestore.collection('chats').doc(chatId).collection('messages');
  }

  DocumentReference<Map<String, dynamic>> _chatRef(String chatId) {
    return _firestore.collection('chats').doc(chatId);
  }

  String newMessageId(String chatId) {
    return _messagesRef(chatId).doc().id;
  }

  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _messagesRef(chatId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<ChatThread>> streamWorkerChats(String workerId) {
    return _firestore
        .collection('chats')
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => ChatThread.fromFirestore(doc))
              .toList();
          items.sort((a, b) {
            final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return items;
        });
  }

  Stream<List<ChatThread>> streamClientChats(String clientId) {
    return _firestore
        .collection('chats')
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => ChatThread.fromFirestore(doc))
              .toList();
          items.sort((a, b) {
            final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return items;
        });
  }

  Future<void> ensureChatThread({
    required String chatId,
    required String clientId,
    required String workerId,
    String? orderId,
    String? clientName,
    String? clientAvatarUrl,
    String? workerName,
    String? workerAvatarUrl,
  }) async {
    final normalizedOrderId = (orderId ?? '').trim();
    if (normalizedOrderId.isEmpty) return;

    final data = _withoutNulls({
      'clientId': clientId,
      'workerId': workerId,
      'orderId': normalizedOrderId,
      'participants': [clientId, workerId],
      'clientName': clientName,
      'clientAvatarUrl': clientAvatarUrl,
      'workerName': workerName,
      'workerAvatarUrl': workerAvatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final ref = _chatRef(chatId);
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      await ref.set(<String, dynamic>{
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> updateChatPreview({
    required String chatId,
    required String clientId,
    required String workerId,
    String? orderId,
    required String lastMessage,
    required String lastMessageType,
    required String lastSenderId,
    String? clientName,
    String? clientAvatarUrl,
    String? workerName,
    String? workerAvatarUrl,
  }) async {
    final data = _withoutNulls({
      'clientId': clientId,
      'workerId': workerId,
      'orderId': orderId,
      'participants': [clientId, workerId],
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastSenderId': lastSenderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'clientName': clientName,
      'clientAvatarUrl': clientAvatarUrl,
      'workerName': workerName,
      'workerAvatarUrl': workerAvatarUrl,
    });

    await _chatRef(chatId).set(data, SetOptions(merge: true));
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String messageId,
    required String senderId,
    required String text,
  }) async {
    final data = ChatMessage(
      id: messageId,
      type: ChatMessageType.text,
      senderId: senderId,
      text: text,
    ).toFirestore();

    await _messagesRef(chatId).doc(messageId).set(data);
  }

  Future<void> sendVoiceMessage({
    required String chatId,
    required String messageId,
    required String senderId,
    required String audioUrl,
  }) async {
    final data = ChatMessage(
      id: messageId,
      type: ChatMessageType.voice,
      senderId: senderId,
      audioUrl: audioUrl,
    ).toFirestore();

    await _messagesRef(chatId).doc(messageId).set(data);
  }

  Future<void> sendImageMessage({
    required String chatId,
    required String messageId,
    required String senderId,
    required List<String> imageUrls,
  }) async {
    final data = ChatMessage(
      id: messageId,
      type: ChatMessageType.image,
      senderId: senderId,
      imageUrls: imageUrls,
    ).toFirestore();

    await _messagesRef(chatId).doc(messageId).set(data);
  }

  Stream<bool> streamUserPresence(String uid) {
    return _firestore.collection('presence').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      return (data?['isOnline'] as bool?) ?? false;
    });
  }

  Future<void> setUserPresence({
    required String uid,
    required bool isOnline,
  }) async {
    await _firestore.collection('presence').doc(uid).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Map<String, dynamic> _withoutNulls(Map<String, dynamic> data) {
    final clean = <String, dynamic>{};
    data.forEach((key, value) {
      if (value != null) {
        clean[key] = value;
      }
    });
    return clean;
  }
}
