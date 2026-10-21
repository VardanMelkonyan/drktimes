import 'package:flutter/material.dart';

class DrkApp extends StatelessWidget {
  const DrkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'drktimes',
      theme: ThemeData.dark(),
      home: const Scaffold(body: Center(child: Text('drktimes'))),
    );
  }
}
