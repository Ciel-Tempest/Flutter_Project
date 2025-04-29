import 'package:customer_atlas_mindmap/main.dart'; // Import your main app file
import 'package:customer_atlas_mindmap/screens/mind_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyApp builds correctly and shows MindMapScreen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    // Wrap with ProviderScope for Riverpod state management
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify that MaterialApp is built.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify that the MindMapScreen is the initial home screen.
    // Note: MindMapScreen itself might show a loading indicator initially
    // due to providers. A full test would involve mocking providers,
    // but this checks if it's part of the widget tree.
    expect(find.byType(MindMapScreen), findsOneWidget);

    // Verify the theme is set to dark mode
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
    expect(materialApp.darkTheme?.brightness, Brightness.dark);
    expect(materialApp.title, 'Customer Atlas Mind Map');
  });
}
