import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderService {
  static final AudioRecorderService _instance = AudioRecorderService._internal();
  factory AudioRecorderService() => _instance;
  AudioRecorderService._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentPath;

  Future<bool> startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        return false;
      }
      final directory = await getTemporaryDirectory();
      _currentPath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: _currentPath!,
      );

      _isRecording = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Recording error: $e');
      }
      return false;
    }
  }

  Future<File?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;

      if (path != null) {
        return File(path);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Stop recording error: $e');
      }
      return null;
    }
  }

  bool get isRecording => _isRecording;
}