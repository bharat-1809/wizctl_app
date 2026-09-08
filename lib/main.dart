import 'package:flutter/material.dart';

void main() {
  runApp(const WizCtlApp());
}

/// Placeholder root; Task 28 replaces it with the real bootstrap.
class WizCtlApp extends StatelessWidget {
  const WizCtlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'WizCtl',
      home: Scaffold(body: Center(child: Text('WizCtl'))),
    );
  }
}
