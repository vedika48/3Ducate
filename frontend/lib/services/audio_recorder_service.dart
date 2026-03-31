import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderService {
  static final AudioRecorderService _instance = AudioRecorderService._internal();
  factory AudioRecorderService() => _instance;
  AudioRecorderService._internal();

  bool _isRecording = false;
  String? _currentPath;

  Future<bool> startRecording() async {
    try {
      final directory = await getTemporaryDirectory();
      _currentPath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      await AudioRecorder.start(
        path: _currentPath,
        audioOutputFormat: AudioOutputFormat.WAV,
      );

      _isRecording = true;
      return true;
    } catch (e) {
      print('Recording error: $e');
      return false;
    }
  }

  Future<File?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      await AudioRecorder.stop();
      _isRecording = false;

      if (_currentPath != null) {
        return File(_currentPath!);
      }
      return null;
    } catch (e) {
      print('Stop recording error: $e');
      return null;
    }
  }

  bool get isRecording => _isRecording;
}