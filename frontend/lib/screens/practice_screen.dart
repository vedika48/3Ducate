import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  UnityWidgetController? _unityWidgetController;

  void onUnityCreated(UnityWidgetController controller) {
    _unityWidgetController = controller;
  }

  @override
  void dispose() {
    _unityWidgetController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Shop Practice'),
      ),
      body: SafeArea(
        bottom: false,
        child: UnityWidget(
          onUnityCreated: onUnityCreated,
        ),
      ),
    );
  }
}