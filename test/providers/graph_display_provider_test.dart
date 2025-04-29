import 'package:customer_atlas_mindmap/models/mind_map_node.dart';
import 'package:customer_atlas_mindmap/providers/graph_data_provider.dart';
import 'package:customer_atlas_mindmap/providers/graph_display_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

// Helper to create a simple mock graph
Graph createMockFullGraph() {
  final graph = Graph();
  final nodeAData = MindMapNode(
    id: 1,
    label: 'Node A',
    level: 1,
    originalData: {},
  );
  final nodeBData = MindMapNode(
    id: 2,
    label: 'Node B',
    level: 2,
    originalData: {},
  );
  final nodeCData = MindMapNode(
    id: 3,
    label: 'Node C',
    level: 2,
    originalData: {},
  );
  final nodeDData = MindMapNode(
    id: 4,
    label: 'Node D',
    level: 3,
    originalData: {},
  );

  final nodeA = Node.Id(nodeAData);
  final nodeB = Node.Id(nodeBData);
  final nodeC = Node.Id(nodeCData);
  final nodeD = Node.Id(nodeDData);

  graph.addNodes([nodeA, nodeB, nodeC, nodeD]);
  graph.addEdge(nodeA, nodeB);
  graph.addEdge(nodeA, nodeC);
  graph.addEdge(nodeB, nodeD);

  return graph;
}

void main() {
  late ProviderContainer container;
  late Graph mockGraph;

  setUp(() {
    mockGraph = createMockFullGraph();
    // Create a ProviderContainer, overriding the dependency
    container = ProviderContainer(
      overrides: [
        // Override fullGraphProvider to return a future of our mock graph
        fullGraphProvider.overrideWith((ref) async => mockGraph),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('Initial build creates Begin node and connects Level 1 nodes', () async {
    // Read the provider to trigger the build
    final initialState = await container.read(graphDisplayProvider.future);

    expect(initialState, isA<GraphDisplayState>());
    final displayedGraph = initialState.displayedGraph;

    // Check for Begin node
    final beginNode = displayedGraph.nodes.firstWhere(
      (n) => (n.key?.value as MindMapNode).id == beginNodeId,
    );
    expect(beginNode, isNotNull);
    expect((beginNode.key?.value as MindMapNode).label, 'Begin');
    expect((beginNode.key?.value as MindMapNode).level, 0);

    // Check for Level 1 nodes from mock graph
    final level1Node = displayedGraph.nodes.firstWhere(
      (n) => (n.key?.value as MindMapNode).id == 1,
    ); // Node A
    expect(level1Node, isNotNull);
    expect((level1Node.key?.value as MindMapNode).label, 'Node A');

    // Check total node count (Begin + Level 1 nodes)
    expect(displayedGraph.nodeCount, 2); // Begin + Node A

    // Check edge count (Begin -> Level 1)
    expect(displayedGraph.edges.length, 1);
    expect(displayedGraph.edges.first.source, equals(beginNode));
    expect(displayedGraph.edges.first.destination, equals(level1Node));

    // Check initial expanded/active state
    expect(initialState.expandedNodeIds, isEmpty);
    expect(initialState.lastTappedNodeId, isNull);
  });

  test('toggleNode expands a collapsed node correctly', () async {
    // Get initial state
    await container.read(graphDisplayProvider.future); // Ensure built
    final notifier = container.read(graphDisplayProvider.notifier);
    final nodeToToggle = mockGraph.nodes.firstWhere(
      (n) => (n.key?.value as MindMapNode).id == 1,
    ); // Node A

    // Act: Toggle Node A (initially collapsed)
    notifier.toggleNode(nodeToToggle);

    // Allow state update
    await container.pump();

    // Assert: Check the new state
    final newState = await container.read(graphDisplayProvider.future);
    final displayedGraph = newState.displayedGraph;

    // Nodes B and C (children of A) should now be present
    expect(
      displayedGraph.nodes.any((n) => (n.key?.value as MindMapNode).id == 2),
      isTrue,
    ); // Node B
    expect(
      displayedGraph.nodes.any((n) => (n.key?.value as MindMapNode).id == 3),
      isTrue,
    ); // Node C
    expect(displayedGraph.nodeCount, 4); // Begin, A, B, C

    // Edges from A to B and A to C should exist
    expect(
      displayedGraph.edges.any(
        (e) =>
            e.source == nodeToToggle &&
            (e.destination.key?.value as MindMapNode).id == 2,
      ),
      isTrue,
    );
    expect(
      displayedGraph.edges.any(
        (e) =>
            e.source == nodeToToggle &&
            (e.destination.key?.value as MindMapNode).id == 3,
      ),
      isTrue,
    );
    expect(displayedGraph.edges.length, 3); // Begin->A, A->B, A->C

    // Check expanded/active state
    expect(newState.expandedNodeIds, contains(1)); // Node A is expanded
    expect(newState.lastTappedNodeId, 1); // Node A is active
  });

  test('toggleNode collapses an expanded node correctly', () async {
    // Setup: Get initial state and expand Node A first
    await container.read(graphDisplayProvider.future);
    final notifier = container.read(graphDisplayProvider.notifier);
    final nodeA = mockGraph.nodes.firstWhere(
      (n) => (n.key?.value as MindMapNode).id == 1,
    );
    notifier.toggleNode(nodeA); // Expand A
    await container.pump();

    final expandedState = await container.read(graphDisplayProvider.future);
    expect(expandedState.expandedNodeIds, contains(1));
    expect(expandedState.displayedGraph.nodeCount, 4); // Begin, A, B, C

    // Act: Toggle Node A again (now expanded)
    notifier.toggleNode(nodeA);
    await container.pump();

    // Assert: Check the collapsed state
    final collapsedState = await container.read(graphDisplayProvider.future);
    final displayedGraph = collapsedState.displayedGraph;

    // Nodes B and C should be removed
    expect(
      displayedGraph.nodes.any((n) => (n.key?.value as MindMapNode).id == 2),
      isFalse,
    ); // Node B removed
    expect(
      displayedGraph.nodes.any((n) => (n.key?.value as MindMapNode).id == 3),
      isFalse,
    ); // Node C removed
    expect(displayedGraph.nodeCount, 2); // Begin, A

    // Edges from A should be removed
    expect(displayedGraph.edges.length, 1); // Only Begin->A

    // Check expanded/active state
    expect(collapsedState.expandedNodeIds, isEmpty); // Node A is collapsed
    expect(
      collapsedState.lastTappedNodeId,
      1,
    ); // Node A is still the last tapped
  });

  test('toggleNode does not expand or collapse Begin node', () async {
    await container.read(graphDisplayProvider.future);
    final notifier = container.read(graphDisplayProvider.notifier);
    final initialNodes =
        container
            .read(graphDisplayProvider)
            .value!
            .displayedGraph
            .nodes
            .toList();
    final initialEdges =
        container
            .read(graphDisplayProvider)
            .value!
            .displayedGraph
            .edges
            .toList();

    final beginNode = initialNodes.firstWhere(
      (n) => (n.key?.value as MindMapNode).id == beginNodeId,
    );

    // Act
    notifier.toggleNode(beginNode);
    await container.pump();

    // Assert
    final newState = await container.read(graphDisplayProvider.future);
    // Graph structure should not change
    expect(newState.displayedGraph.nodes, equals(initialNodes));
    expect(newState.displayedGraph.edges, equals(initialEdges));
    expect(newState.expandedNodeIds, isEmpty); // Still empty
    expect(newState.lastTappedNodeId, beginNodeId); // Active node updated
  });

  test('setActiveNode updates lastTappedNodeId', () async {
    await container.read(graphDisplayProvider.future); // ensure built
    final notifier = container.read(graphDisplayProvider.notifier);

    // Act
    notifier.setActiveNode(999); // Set an arbitrary ID
    await container.pump();

    // Assert
    final newState = await container.read(graphDisplayProvider.future);
    expect(newState.lastTappedNodeId, 999);
  });
}
