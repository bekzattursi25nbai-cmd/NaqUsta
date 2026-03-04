// lib/widgets/chat/voice_message_bubble.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  final String? timeLabel;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.isMe,
    this.timeLabel,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isReady = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (!_isReady) {
      await _player.setUrl(widget.audioUrl);
      _isReady = true;
    }

    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.isMe ? Colors.black : Colors.grey.shade200;
    final foreground = widget.isMe ? Colors.white : Colors.black87;

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data?.playing ?? false;
                    return IconButton(
                      onPressed: _togglePlay,
                      icon: Icon(
                        isPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: foreground,
                        size: 28,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                StreamBuilder<Duration?>(
                  stream: _player.durationStream,
                  builder: (context, snapshot) {
                    final duration = snapshot.data;
                    return StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (context, positionSnapshot) {
                        final position = positionSnapshot.data ?? Duration.zero;
                        final total = duration ?? Duration.zero;
                        final progress = total.inMilliseconds == 0
                            ? 0.0
                            : position.inMilliseconds / total.inMilliseconds;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 160,
                              child: LinearProgressIndicator(
                                value: progress.clamp(0, 1).toDouble(),
                                backgroundColor:
                                    foreground.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.isMe
                                      ? Colors.amber
                                      : Colors.black87,
                                ),
                                minHeight: 3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDuration(total),
                              style: TextStyle(
                                color: foreground.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            if (widget.timeLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                widget.timeLabel!,
                style: TextStyle(
                  color: foreground.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
