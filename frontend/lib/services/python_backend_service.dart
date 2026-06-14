import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class PythonBackendService {
  // For emulator: use 10.0.2.2 for localhost
  // For real device: use your computer's IP address
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // static const String baseUrl = 'http://192.168.1.100:8000'; // Real device

  WebSocketChannel? _channel;

  static Future<Map<String, dynamic>> speechToText(File audioFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/speech-to-text'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
      ));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      return jsonDecode(responseData);
    } catch (e) {
      return {'error': e.toString(), 'text': ''};
    }
  }

  static Future<Map<String, dynamic>> analyzeSpeech(String text, {String scenario = 'cafe'}) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/api/analyze-speech'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'scenario': scenario}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<String?> textToSpeech(String text, {String language = 'en'}) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/api/text-to-speech?text=${Uri.encodeComponent(text)}&language=$language'),
      );

      if (response.statusCode == 200) {
        // Save to temporary file and return path
        return _saveAudioToFile(response.bodyBytes);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('TTS error: $e');
      }
      return null;
    }
  }

  static Future<String?> _saveAudioToFile(List<int> audioData) async {
    try {
      final directory = Directory.systemTemp;
      final file = File('${directory.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await file.writeAsBytes(audioData);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  void connectWebSocket(Function(Map<String, dynamic>) onMessage) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:8000/ws'));
      _channel!.stream.listen(
            (data) {
          final message = jsonDecode(data);
          onMessage(message);
        },
        onError: (error) {
          if (kDebugMode) {
            print('WebSocket error: $error');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('WebSocket connection error: $e');
      }
    }
  }

  void sendToUnity(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void disconnectWebSocket() {
    _channel?.sink.close();
  }
}