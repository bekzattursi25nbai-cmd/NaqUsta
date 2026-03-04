// lib/services/voice_record_service.dart
import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecordService {
  final AudioRecorder _record = AudioRecorder();
  final StreamController<File> _recordingController =
      StreamController<File>.broadcast();
  Timer? _autoStopTimer;

  Stream<File> get onRecordingComplete => _recordingController.stream;

  Future<bool> hasPermission() async {
    return _record.hasPermission();
  }

  Future<void> startRecording({int maxSeconds = 13}) async {
    if (await _record.isRecording()) {
      return;
    }

    final allowed = await _record.hasPermission();
    if (!allowed) {
      throw Exception('Microphone permission denied');
    }

    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _record.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(Duration(seconds: maxSeconds), () async {
      await stopRecording();
    });
  }

  Future<File?> stopRecording() async {
    if (!await _record.isRecording()) {
      return null;
    }

    final path = await _record.stop();
    _autoStopTimer?.cancel();

    if (path == null) {
      return null;
    }

    final file = File(path);
    if (await file.exists()) {
      _recordingController.add(file);
      return file;
    }
    return null;
  }

  Future<String> uploadVoiceFile({
    required String uid,
    required String chatId,
    required String messageId,
    required File file,
  }) async {
    final ref = FirebaseStorage.instance.ref().child(
      'uploads/$uid/audio/chats/$chatId/$messageId.m4a',
    );

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'audio/m4a'),
    );

    return task.ref.getDownloadURL();
  }

  Future<List<String>> uploadCompressedImages({
    required String uid,
    required String chatId,
    required String messageId,
    required List<XFile> images,
  }) async {
    final limited = images.take(3).toList();
    final urls = <String>[];

    final tempDir = await getTemporaryDirectory();

    for (var i = 0; i < limited.length; i++) {
      final source = limited[i];
      final targetPath = '${tempDir.path}/chat_${messageId}_$i.jpg';

      final compressed = await FlutterImageCompress.compressAndGetFile(
        source.path,
        targetPath,
        quality: 70,
        minWidth: 1280,
        minHeight: 1280,
      );

      final file = File((compressed ?? XFile(source.path)).path);
      final ref = FirebaseStorage.instance.ref().child(
        'uploads/$uid/images/chats/$chatId/${messageId}_$i.jpg',
      );

      final task = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      urls.add(await task.ref.getDownloadURL());
    }

    return urls;
  }

  Future<void> dispose() async {
    _autoStopTimer?.cancel();
    await _recordingController.close();
    await _record.dispose();
  }
}
