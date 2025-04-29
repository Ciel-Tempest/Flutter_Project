// lib/providers/graph_display_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'graph_data_provider.dart'; // Access the full graph provider
import '../models/mind_map_node.dart';
import 'dart:collection'; // For HashSet

part 'graph_display_provider.g.dart';

// Define a constant ID for the static "Begin" node
const int beginNodeId = -1;

// State class to hold the displayed graph and expanded nodes
class GraphDisplayState {
  final Graph displayedGraph;
  final Set<int> expandedNodeIds;
  final int? lastTappedNodeId;

  GraphDisplayState({
    required this.displayedGraph,
    required this.expandedNodeIds,
    this.lastTappedNodeId,
  });

  GraphDisplayState copyWith({
    Graph? displayedGraph,
    Set<int>? expandedNodeIds,
    int? lastTappedNodeId,
  }) {
    return GraphDisplayState(
      displayedGraph: displayedGraph ?? this.displayedGraph,
      expandedNodeIds: expandedNodeIds ?? this.expandedNodeIds,
      lastTappedNodeId: lastTappedNodeId ?? this.lastTappedNodeId,
    );
  }
}

@riverpod
class GraphDisplay extends _$GraphDisplay {
  Graph? _fullGraph;

  void setActiveNode(int nodeId) {
     final currentState = state.value;
     // Only update if the state exists and the active node is actually changing
     if (currentState != null && currentState.lastTappedNodeId != nodeId) {
         state = AsyncData(currentState.copyWith(lastTappedNodeId: nodeId));
         print("Set active node ID: $nodeId");
     }
  }
// (Display all)
//   @override
// FutureOr<GraphDisplayState> build() async {
//   _fullGraph = await ref.watch(fullGraphProvider.future);

//   if (_fullGraph == null || _fullGraph!.nodeCount() == 0) {
//     print("Warning: Full graph is null or empty.");
//     return GraphDisplayState(
//       displayedGraph: Graph(),
//       expandedNodeIds: {},
//       lastTappedNodeId: null,
//     );
//   }

//   final fullGraphCopy = Graph();

//   // Clone all nodes
//   for (var node in _fullGraph!.nodes) {
//     fullGraphCopy.addNode(node);
//   }

//   // Clone all edges
//   for (var edge in _fullGraph!.edges) {
//     fullGraphCopy.addEdge(edge.source, edge.destination);
//   }

//   // Collect all node IDs as expanded
//   final allExpandedIds = _fullGraph!.nodes
//       .map((n) => (n.key?.value as MindMapNode).id)
//       .toSet();

//   print("Full graph pre-expanded: ${_fullGraph!.nodeCount()} nodes, ${_fullGraph!.edges.length} edges");

//   return GraphDisplayState(
//     displayedGraph: fullGraphCopy,
//     expandedNodeIds: allExpandedIds,
//     lastTappedNodeId: null,
//   );
// }

  @override
  FutureOr<GraphDisplayState> build() async {
    _fullGraph = await ref.watch(fullGraphProvider.future);
    final initialGraph = Graph();
    final initialExpandedIds = HashSet<int>();

    // --- Create and Add "Begin" Node ---
    final beginNodeData = MindMapNode(
      id: beginNodeId, // Use the constant ID
      label: "Begin",
      level: 0, // Assign level 0
      originalData: {}, // No original data
    );
    final beginGraphNode = Node.Id(beginNodeData);
    initialGraph.addNode(beginGraphNode);
    // --- End "Begin" Node ---

    if (_fullGraph != null && _fullGraph!.nodeCount() > 0) {
      // Find actual Level 1 nodes from the full graph
      final level1Nodes = _fullGraph!.nodes.where((node) {
        final nodeData = node.key?.value as MindMapNode?;
        return nodeData?.level == 1;
      }).toList();

      // Add Level 1 nodes and edges from "Begin" to them
      for (var level1Node in level1Nodes) {
        initialGraph.addNode(level1Node); // Add to displayed graph
        initialGraph.addEdge(beginGraphNode, level1Node); // Connect to Begin
      }
       print("Initial display graph created with Begin node and ${level1Nodes.length} Level 1 children.");
    } else {
       print("Warning: Full graph is null or empty. Only Begin node added.");
    }

    return GraphDisplayState(
      displayedGraph: initialGraph,
      expandedNodeIds: initialExpandedIds,
      lastTappedNodeId: null, // No node active initially
    );
  }

  void toggleNode(Node nodeToToggle) {
    final nodeData = nodeToToggle.key?.value as MindMapNode?;
    if (nodeData == null) return;

    // --- Prevent toggling the "Begin" node ---
    if (nodeData.id == beginNodeId) {
      print("Cannot toggle the 'Begin' node.");
      // Optionally update lastTappedNodeId even if not toggling
      final currentState = state.value;
       if (currentState != null && currentState.lastTappedNodeId != beginNodeId) {
           state = AsyncData(currentState.copyWith(lastTappedNodeId: beginNodeId));
       }
      return;
    }
    // --- End Prevent Toggle ---

    if (_fullGraph == null) return;
    final currentState = state.value;
    if (currentState == null) return;

    final currentGraph = currentState.displayedGraph;
    final currentExpandedIds = HashSet<int>.from(currentState.expandedNodeIds);
    bool isCurrentlyExpanded = currentExpandedIds.contains(nodeData.id);

    print("Toggling node: ${nodeData.label} (ID: ${nodeData.id}), Currently Expanded: $isCurrentlyExpanded");

    if (isCurrentlyExpanded) {
      // --- Collapse Node ---
      final nodesToRemove = <Node>{};
      // final edgesToRemove = <Edge>{}; // This was leftover and incorrect, remove
      final queue = Queue<Node>.from([nodeToToggle]);
      final visited = <Node>{nodeToToggle};

      while (queue.isNotEmpty) {
        final currentNode = queue.removeFirst();
        final successors = currentGraph.successorsOf(currentNode);
        for (var successor in successors) {
          if (visited.add(successor)) {
            nodesToRemove.add(successor);
            queue.add(successor);
            final successorData = successor.key?.value as MindMapNode?;
            if (successorData != null) {
              currentExpandedIds.remove(successorData.id);
            }
          }
        }
      }

      // --- Corrected Print Statement ---
      print("Collapsing: Removing ${nodesToRemove.length} nodes.");
      nodesToRemove.forEach(currentGraph.removeNode); // Edges removed automatically
      currentExpandedIds.remove(nodeData.id);

    } else {
      // --- Expand Node ---
      final childrenInFullGraph = _fullGraph!.successorsOf(nodeToToggle);
      print("Expanding: Found ${childrenInFullGraph.length} children in full graph.");
      for (var childNode in childrenInFullGraph) {
        // Add child node if not already present
        if (currentGraph.nodes.every((n) => n.key?.value != childNode.key?.value)) {
           print("Adding child node: ${(childNode.key?.value as MindMapNode).label}");
           currentGraph.addNode(childNode);
        } else {
           print("Child node already exists: ${(childNode.key?.value as MindMapNode).label}");
        }
        // Add edge if not already present
        if (currentGraph.edges.every((e) => !(e.source == nodeToToggle && e.destination == childNode))) {
           print("Adding edge: ${nodeData.label} -> ${(childNode.key?.value as MindMapNode).label}");
           currentGraph.addEdge(nodeToToggle, childNode);
        } else {
           print("Edge already exists: ${nodeData.label} -> ${(childNode.key?.value as MindMapNode).label}");
        }
      }
      currentExpandedIds.add(nodeData.id);
    }

    state = AsyncData(
      currentState.copyWith(
        displayedGraph: currentGraph,
        expandedNodeIds: currentExpandedIds,
        lastTappedNodeId: nodeData.id, // Update active node ID
      ),
    );
    print("State updated. Active Node ID: ${state.value?.lastTappedNodeId}, Displayed nodes: ${state.value?.displayedGraph.nodeCount}, Expanded IDs: ${state.value?.expandedNodeIds.length}");
  }
}