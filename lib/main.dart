// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/mind_map_screen.dart';

void main() {
  runApp(
    // Wrap the entire app in a ProviderScope
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Atlas Mind Map',
      themeMode: ThemeMode.dark, // Use dark mode
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color.fromARGB(
          255,
          65,
          34,
          1,
        ), // Deep dark blue/purple
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE0AFFF), // Light purple/pink
          secondary: Color(0xFF00F5D4), // Bright cyan/teal
          surface: Color(0xFF16213E), // Slightly lighter dark blue
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Color(0xFFC0C0FF), // Light lavender for text
          background: Color(0xFF1A1A2E),
          onBackground: Color(0xFFC0C0FF),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFC0C0FF)),
          titleMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Define other theme properties if needed
      ),
      home: const MindMapScreen(),
    );
  }
}
