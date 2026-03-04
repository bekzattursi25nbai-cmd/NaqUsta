// lib/screens/chat/chat_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kuryl_kz/models/chat_message.dart';
import 'package:kuryl_kz/services/chat_service.dart';
import 'package:kuryl_kz/services/voice_record_service.dart';
import 'package:kuryl_kz/core/widgets/app_back_button.dart';
import 'package:kuryl_kz/widgets/chat/text_message_bubble.dart';
import 'package:kuryl_kz/widgets/chat/voice_message_bubble.dart';
import 'package:kuryl_kz/core/widgets/safe_network_image.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String? orderId;
  final String clientId;
  final String workerId;
  final String currentUserId;
  final String peerUserId;
  final String peerName;
  final String? peerAvatarUrl;

  const ChatScreen({
    super.key,
    this.chatId,
    this.orderId,
    required this.clientId,
    required this.workerId,
    required this.currentUserId,
    required this.peerUserId,
    required this.peerName,
    this.peerAvatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final VoiceRecordService _voiceService = VoiceRecordService();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  late final String _chatId;
  StreamSubscription<File>? _recordSub;

  bool _isSending = false;
  bool _isRecording = false;
  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    final providedChatId = widget.chatId?.trim() ?? '';
    _chatId = providedChatId.isNotEmpty
        ? providedChatId
        : ChatService.buildChatId(widget.clientId, widget.workerId);
    _recordSub = _voiceService.onRecordingComplete.listen(_handleRecordedFile);
    _chatService.setUserPresence(uid: widget.currentUserId, isOnline: true);
    _ensureChatThread();
  }

  @override
  void dispose() {
    _recordSub?.cancel();
    _voiceService.dispose();
    _messageController.dispose();
    _chatService.setUserPresence(uid: widget.currentUserId, isOnline: false);
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _currentIsWorker => widget.currentUserId == widget.workerId;

  void _ensureChatThread() {
    _chatService.ensureChatThread(
      chatId: _chatId,
      clientId: widget.clientId,
      workerId: widget.workerId,
      orderId: widget.orderId,
      clientName: _currentIsWorker ? widget.peerName : null,
      clientAvatarUrl: _currentIsWorker ? widget.peerAvatarUrl : null,
      workerName: _currentIsWorker ? null : widget.peerName,
      workerAvatarUrl: _currentIsWorker ? null : widget.peerAvatarUrl,
    );
  }

  Future<void> _updateChatPreview({
    required String message,
    required String type,
  }) async {
    final preview = _shortPreview(message);
    await _chatService.updateChatPreview(
      chatId: _chatId,
      clientId: widget.clientId,
      workerId: widget.workerId,
      orderId: widget.orderId,
      lastMessage: preview,
      lastMessageType: type,
      lastSenderId: widget.currentUserId,
      clientName: _currentIsWorker ? widget.peerName : null,
      clientAvatarUrl: _currentIsWorker ? widget.peerAvatarUrl : null,
      workerName: _currentIsWorker ? null : widget.peerName,
      workerAvatarUrl: _currentIsWorker ? null : widget.peerAvatarUrl,
    );
  }

  String _shortPreview(String text, {int max = 80}) {
    final trimmed = text.trim();
    if (trimmed.length <= max) return trimmed;
    return '${trimmed.substring(0, max)}…';
  }

  Future<void> _toggleRecording() async {
    if (_isSending) return;

    if (_isRecording) {
      await _voiceService.stopRecording();
      setState(() => _isRecording = false);
      return;
    }

    try {
      final allowed = await _voiceService.hasPermission();
      if (!allowed) {
        _showError('Микрофонға рұқсат беріңіз');
        return;
      }
      setState(() => _isRecording = true);
      await _voiceService.startRecording(maxSeconds: 13);
    } catch (e) {
      setState(() => _isRecording = false);
      _showError('Аудио жазу қатесі: $e');
    }
  }

  Future<void> _handleRecordedFile(File file) async {
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _isSending = true;
    });

    try {
      final messageId = _chatService.newMessageId(_chatId);
      final url = await _voiceService.uploadVoiceFile(
        uid: widget.currentUserId,
        chatId: _chatId,
        messageId: messageId,
        file: file,
      );
      await _chatService.sendVoiceMessage(
        chatId: _chatId,
        messageId: messageId,
        senderId: widget.currentUserId,
        audioUrl: url,
      );
      await _updateChatPreview(message: 'Аудио хабарлама', type: 'voice');
      await file.delete();
    } catch (e) {
      _showError('Аудио жіберу қатесі: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickImages() async {
    if (_isSending || _isRecording) return;

    try {
      final files = await _imagePicker.pickMultiImage();
      if (files.isEmpty) return;

      if (files.length > 3) {
        _showError('Бір жолы тек 3 сурет жіберіледі');
      }

      setState(() {
        _selectedImages = files.take(3).toList();
      });
    } catch (e) {
      _showError('Сурет таңдау қатесі: $e');
    }
  }

  Future<void> _sendImages() async {
    if (_selectedImages.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final messageId = _chatService.newMessageId(_chatId);
      final urls = await _voiceService.uploadCompressedImages(
        uid: widget.currentUserId,
        chatId: _chatId,
        messageId: messageId,
        images: _selectedImages,
      );
      await _chatService.sendImageMessage(
        chatId: _chatId,
        messageId: messageId,
        senderId: widget.currentUserId,
        imageUrls: urls,
      );
      final count = urls.length;
      await _updateChatPreview(
        message: count > 1 ? 'Суреттер ($count)' : 'Сурет',
        type: 'image',
      );
      setState(() => _selectedImages = []);
    } catch (e) {
      _showError('Сурет жіберу қатесі: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final messageId = _chatService.newMessageId(_chatId);
      await _chatService.sendTextMessage(
        chatId: _chatId,
        messageId: messageId,
        senderId: widget.currentUserId,
        text: text,
      );
      await _updateChatPreview(message: text, type: 'text');
      _messageController.clear();
    } catch (e) {
      _showError('Хабарлама жіберу қатесі: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _handleSendPressed() {
    if (_messageController.text.trim().isNotEmpty) {
      _sendText();
      return;
    }
    if (_selectedImages.isNotEmpty) {
      _sendImages();
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _buildImageMessage(ChatMessage message, bool isMe) {
    final urls = message.imageUrls ?? [];
    if (urls.isEmpty) return const SizedBox.shrink();

    final background = isMe ? Colors.black : Colors.grey.shade200;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: urls.map((url) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SafeNetworkImage(
                url: url,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSelectedImagesPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        height: 70,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _selectedImages.length,
          separatorBuilder: (_, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final image = _selectedImages[index];
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(image.path),
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImages.removeAt(index);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImages.isNotEmpty) _buildSelectedImagesPreview(),
            if (_isRecording)
              Row(
                children: const [
                  Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
                  SizedBox(width: 6),
                  Text(
                    'Жазып жатыр...',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            Row(
              children: [
                IconButton(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.image_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Хабарлама жазыңыз...',
                      border: InputBorder.none,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
                IconButton(
                  onPressed: _isSending ? null : _handleSendPressed,
                  icon: const Icon(Icons.send),
                ),
                IconButton(
                  onPressed: _toggleRecording,
                  icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic),
                  color: _isRecording ? Colors.red : Colors.black,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.senderId == widget.currentUserId;
    final timeLabel = _formatTime(message.createdAt);

    switch (message.type) {
      case ChatMessageType.system:
        final text = (message.text ?? '').trim();
        if (text.isEmpty) return const SizedBox.shrink();
        return _buildSystemMessage(text);
      case ChatMessageType.voice:
        if (message.audioUrl == null) return const SizedBox.shrink();
        return VoiceMessageBubble(
          audioUrl: message.audioUrl!,
          isMe: isMe,
          timeLabel: timeLabel.isEmpty ? null : timeLabel,
        );
      case ChatMessageType.image:
        return _buildImageMessage(message, isMe);
      case ChatMessageType.text:
        if (message.text == null || message.text!.isEmpty) {
          return const SizedBox.shrink();
        }
        return TextMessageBubble(
          text: message.text!,
          isMe: isMe,
          timeLabel: timeLabel.isEmpty ? null : timeLabel,
        );
    }
  }

  Widget _buildSystemMessage(String text) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: appBarBackButton(context),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[900],
              child:
                  (widget.peerAvatarUrl != null &&
                      widget.peerAvatarUrl!.trim().isNotEmpty)
                  ? ClipOval(
                      child: SafeNetworkImage(
                        url: widget.peerAvatarUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(widget.peerName.isNotEmpty ? widget.peerName[0] : '?'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.peerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StreamBuilder<bool>(
                  stream: _chatService.streamUserPresence(widget.peerUserId),
                  builder: (context, snapshot) {
                    final online = snapshot.data ?? false;
                    return Text(
                      online ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: online ? Colors.green : Colors.grey,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.streamMessages(_chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Қате: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text('Хабарлама жоқ'));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }
}
