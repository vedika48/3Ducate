import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/python_backend_service.dart';
import '../services/audio_recorder_service.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final AudioRecorderService _recorderService = AudioRecorderService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PythonBackendService _backendService = PythonBackendService();

  String _recognizedText = '';
  Map<String, dynamic> _analysis = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _backendService.connectWebSocket(_handleWebSocketMessage);
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    if (message['type'] == 'speech_analysis') {
      setState(() {
        _analysis = message['data'];
      });
    }
  }

  Future<void> _startRecording() async {
    bool started = await _recorderService.startRecording();
    if (started) {
      setState(() {});
    }
  }

  Future<void> _stopRecording() async {
    final audioFile = await _recorderService.stopRecording();
    if (audioFile != null) {
      setState(() {
        _isLoading = true;
      });

      // Send to Python backend for speech recognition
      final result = await PythonBackendService.speechToText(audioFile);

      setState(() {
        _isLoading = false;
        _recognizedText = result['text'] ?? '';
      });

      if (_recognizedText.isNotEmpty) {
        // Analyze the speech
        final analysis = await PythonBackendService.analyzeSpeech(_recognizedText);
        setState(() {
          _analysis = analysis;
        });
      }
    }
  }

  Future<void> _playExample(String text) async {
    final audioPath = await PythonBackendService.textToSpeech(text);
    if (audioPath != null) {
      await _audioPlayer.play(DeviceFileSource(audioPath));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn Phase'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Recording Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Practice Speaking',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _recorderService.isRecording ? null : _startRecording,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Start Recording'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _recorderService.isRecording ? _stopRecording : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Stop Recording'),
                          ),
                        ],
                      ),
                      if (_isLoading) const CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Example Phrases
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Practice Phrases:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _buildPhraseButton('Hello, how are you?'),
                      _buildPhraseButton('I would like a coffee'),
                      _buildPhraseButton('How much does it cost?'),
                      _buildPhraseButton('Thank you very much'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Results
              if (_recognizedText.isNotEmpty) _buildResultsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhraseButton(String phrase) {
    return ListTile(
      title: Text(phrase),
      trailing: IconButton(
        icon: const Icon(Icons.volume_up),
        onPressed: () => _playExample(phrase),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Speech:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_recognizedText),
            const SizedBox(height: 10),

            if (_analysis.isNotEmpty) ...[
              const Text(
                'Analysis:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_analysis['vocabulary_score'] != null)
                Text('Score: ${(_analysis['vocabulary_score'] * 100).toStringAsFixed(1)}%'),
              if (_analysis['matched_categories'] != null)
                Text('Categories: ${_analysis['matched_categories'].join(', ')}'),
              if (_analysis['suggestions'] != null) ...[
                const SizedBox(height: 8),
                const Text('Suggestions:'),
                ..._analysis['suggestions'].map<Widget>((suggestion) =>
                    Text('• $suggestion')
                ).toList(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _backendService.disconnectWebSocket();
    super.dispose();
  }
}