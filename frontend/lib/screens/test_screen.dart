import 'package:flutter/material.dart';
import '../services/python_backend_service.dart';
import '../services/audio_recorder_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final AudioRecorderService _recorderService = AudioRecorderService();

  final List<TestQuestion> _questions = [
    TestQuestion(
      id: 1,
      question: 'Greet the waiter politely',
      expectedCategory: 'greetings',
    ),
    TestQuestion(
      id: 2,
      question: 'Order a cup of coffee',
      expectedCategory: 'ordering',
    ),
    TestQuestion(
      id: 3,
      question: 'Ask for the bill',
      expectedCategory: 'paying',
    ),
  ];

  int _currentQuestionIndex = 0;
  String _userAnswer = '';
  int _score = 0;
  bool _testCompleted = false;

  Future<void> _evaluateAnswer() async {
    if (_userAnswer.isEmpty) return;

    final analysis = await PythonBackendService.analyzeSpeech(_userAnswer);
    final currentQuestion = _questions[_currentQuestionIndex];

    bool isCorrect = analysis['matched_categories']?.contains(currentQuestion.expectedCategory) ?? false;

    if (isCorrect) {
      setState(() {
        _score++;
      });
    }

    // Move to next question or finish test
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _userAnswer = '';
      });
    } else {
      setState(() {
        _testCompleted = true;
      });
    }
  }

  void _restartTest() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _testCompleted = false;
      _userAnswer = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Phase'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_testCompleted) ...[
              Text(
                'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        _questions[_currentQuestionIndex].question,
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Recording controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _recorderService.isRecording ? null : () => _recorderService.startRecording(),
                            child: const Text('Start Recording'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _recorderService.isRecording ? () async {
                              final file = await _recorderService.stopRecording();
                              if (file != null) {
                                final result = await PythonBackendService.speechToText(file);
                                setState(() {
                                  _userAnswer = result['text'] ?? '';
                                });
                              }
                            } : null,
                            child: const Text('Stop & Submit'),
                          ),
                        ],
                      ),

                      if (_userAnswer.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Your answer: $_userAnswer'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _evaluateAnswer,
                          child: const Text('Evaluate Answer'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Test Results
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Test Completed!',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Score: $_score/${_questions.length}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _restartTest,
                        child: const Text('Restart Test'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TestQuestion {
  final int id;
  final String question;
  final String expectedCategory;

  TestQuestion({
    required this.id,
    required this.question,
    required this.expectedCategory,
  });
}