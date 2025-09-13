import 'package:flutter/material.dart';
import 'package:tryagaintext/views/screens/conversations_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.redAccent,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: ConversationsScreen(),
    );
  }
}
