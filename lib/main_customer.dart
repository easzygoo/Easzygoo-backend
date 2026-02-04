import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _CustomerPlaceholderApp());
}

class _CustomerPlaceholderApp extends StatelessWidget {
  const _CustomerPlaceholderApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EaszyGoo Customer',
      home: Scaffold(
        appBar: AppBar(title: const Text('Customer App')),
        body: const Center(child: Text('Coming later')),
      ),
    );
  }
}
