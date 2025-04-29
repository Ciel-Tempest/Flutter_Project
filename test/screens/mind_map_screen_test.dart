// import 'package:customer_atlas_mindmap/models/mind_map_node.dart';
// //import 'package:customer_atlas_mindmap/providers/graph_data_provider.dart';
// import 'package:customer_atlas_mindmap/providers/graph_display_provider.dart';
// import 'package:customer_atlas_mindmap/screens/mind_map_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:graphview/GraphView.dart';
// //import 'package:mockito/mockito.dart'; // If using mockito for notifier mocking

// // --- Mocking Setup (Example using simple overrides) ---

// // Helper to create a simple initial display state
// GraphDisplayState createInitialMockState() {
//   final graph = Graph();
//   final beginData = MindMapNode(id: beginNodeId, label: 'Begin', level: 0, originalData: {});
//   final nodeAData = MindMapNode(id: 1, label: 'Node A', level: 1, originalData: {});
//   final beginNode = Node.Id(beginData);
//   final nodeA = Node.Id(nodeAData);
//   graph.addNodes([beginNode, nodeA]);
//   graph.addEdge(beginNode, nodeA);
//   return GraphDisplayState(
//     displayedGraph: graph,
//     expandedNodeIds: {},
//     lastTappedNodeId: null,
//   );
// }

// // Helper to create an expanded display state
// GraphDisplayState createExpandedMockState() {
//   final graph = Graph();
//   final beginData = MindMapNode(id: beginNodeId, label: 'Begin', level: 0, originalData: {});
//   final nodeAData = MindMapNode(id: 1, label: 'Node A', level: 1, originalData: {});
//   final nodeBData = MindMapNode(id: 2, label: 'Node B', level: 2, originalData: {});
//   final beginNode = Node.Id(beginData);
//   final nodeA = Node.Id(nodeAData);
//   final nodeB = Node.Id(nodeBData);
//   graph.addNodes([beginNode, nodeA, nodeB]);
//   graph.addEdge(beginNode, nodeA);
//   graph.addEdge(nodeA, nodeB); // A is expanded, showing B
//   return GraphDisplayState(
//     displayedGraph: graph,
//     expandedNodeIds: {1}, // Node A is expanded
//     lastTappedNodeId: 1, // Node A was last tapped
//   );
// }

// // --- End Mocking Setup ---

// void main() {
//   testWidgets('MindMapScreen shows loading indicator initially', (tester) async {
//     await tester.pumpWidget(
//       ProviderScope(
//         // Override the provider to be in loading state
//         overrides: [
//           graphDisplayProvider.overrideWith((ref) => AsyncLoading<GraphDisplayState>())
//         ],
//         child: const MaterialApp(home: MindMapScreen()),
//       ),
//     );

//     expect(find.byType(CircularProgressIndicator), findsOneWidget);
//     expect(find.byType(GraphView), findsNothing);
//   });

//   testWidgets('MindMapScreen shows error message on error', (tester) async {
//     final testError = Exception('Failed to load graph');
//     await tester.pumpWidget(
//       ProviderScope(
//         // Override the provider with an error state
//         overrides: [
//           graphDisplayProvider.overrideWith((ref) => Stream.value(AsyncError<GraphDisplayState>(testError, StackTrace.current)))
//         ],
//         child: const MaterialApp(home: MindMapScreen()),
//       ),
//     );
//     await tester.pumpAndSettle(); // Allow widget to rebuild

//     expect(find.textContaining('Error building graph view'), findsOneWidget);
//     expect(find.byType(GraphView), findsNothing);
//   });

//   testWidgets('MindMapScreen displays initial graph correctly', (tester) async {
//     await tester.pumpWidget(
//       ProviderScope(
//         // Override with initial mock data
//         overrides: [
//           graphDisplayProvider.overrideWith((ref) => Stream.value(AsyncData(createInitialMockState())))
//         ],
//         child: const MaterialApp(home: MindMapScreen()),
//       ),
//     );
//     await tester.pumpAndSettle(); // Allow graph view to build

//     expect(find.byType(GraphView), findsOneWidget);
//     expect(find.text('Begin'), findsOneWidget);
//     expect(find.text('Node A'), findsOneWidget);
//     expect(find.text('Node B'), findsNothing); // Node B shouldn't be visible yet
//   });

//   testWidgets('MindMapScreen displays expanded graph correctly', (tester) async {
//     await tester.pumpWidget(
//       ProviderScope(
//         // Override with expanded mock data
//         overrides: [
//           graphDisplayProvider.overrideWith((ref) => Stream.value(AsyncData(createExpandedMockState())))
//         ],
//         child: const MaterialApp(home: MindMapScreen()),
//       ),
//     );
//      await tester.pumpAndSettle();

//     expect(find.byType(GraphView), findsOneWidget);
//     expect(find.text('Begin'), findsOneWidget);
//     expect(find.text('Node A'), findsOneWidget);
//     expect(find.text('Node B'), findsOneWidget); // Node B is now visible
//   });

//    // Test tapping requires more advanced mocking of the Notifier itself
//    // or checking state changes after tap. Simpler check: find GestureDetector.
//    testWidgets('Nodes have GestureDetector for interaction', (tester) async {
//      await tester.pumpWidget(
//        ProviderScope(
//          overrides: [
//            graphDisplayProvider.overrideWith((ref) => Stream.value(AsyncData(createInitialMockState())))
//          ],
//          child: const MaterialApp(home: MindMapScreen()),
//        ),
//      );
//       await tester.pumpAndSettle();

//      // Find the widget associated with Node A text
//      final nodeAWidgetFinder = find.ancestor(of: find.text('Node A'), matching: find.byType(GestureDetector));
//      expect(nodeAWidgetFinder, findsOneWidget, reason: "Node A should be tappable");
//    });

// }
