// lib/layout/circular_layout_algorithm.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../models/mind_map_node.dart'; // Access level info

class CircularLayoutAlgorithm implements Algorithm {
  final double layerDistance; // Distance between concentric circles
  final double
  nodeDistanceWithinLayer; // Base distance between nodes on the same circle
  final Map<int, Node> nodeMap; // Map node ID to Node object
  final Graph fullGraph; // Access to the full graph for parent/sibling info
  late double _width, _height;

  CircularLayoutAlgorithm({
    required this.fullGraph,
    required this.nodeMap,
    this.layerDistance = 150.0, // Adjust as needed
    this.nodeDistanceWithinLayer = 80.0, // Adjust as needed
  });

  @override
  EdgeRenderer? renderer; // Not used for positioning, can be null

  @override
  void setDimensions(double width, double height) {
    _width = width;
    _height = height;
  }

  @override
  void setFocusedNode(Node node) {
    // No-op unless you want to center or highlight a node
  }

  @override
  void init(Graph? graph) {
    // Can potentially pre-calculate some things here if needed
  }

  @override
  void step(Graph? graph) {
    // This algorithm calculates final positions in one go in 'run',
    // so 'step' might not be needed for this specific implementation.
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null || graph.nodeCount == 0) {
      return const Size(0, 0);
    }

    // Map to store calculated positions to avoid recalculating for shared ancestors
    //final center = Offset(_width / 2, _height / 2);

    final Map<int, Offset> calculatedPositions = {};
    // Keep track of min/max coordinates to calculate overall size
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    // Start positioning from Level 1 nodes
    final level1Nodes =
        graph.nodes
            .where((n) => (n.key?.value as MindMapNode?)?.level == 1)
            .toList();

    if (level1Nodes.isEmpty) return const Size(0, 0);

    // --- Position Level 1 Nodes ---
    final double level1Radius =
        layerDistance; // Or layerDistance / 2? Place them around center
    final double angleStep1 = (2 * pi) / max(1, level1Nodes.length);

    for (int i = 0; i < level1Nodes.length; i++) {
      final node = level1Nodes[i];
      final nodeData = node.key?.value as MindMapNode?;
      if (nodeData == null) continue;

      final angle = i * angleStep1;
      final x = level1Radius * cos(angle);
      final y = level1Radius * sin(angle);
      final pos = Offset(x, y);
      calculatedPositions[nodeData.id] = pos;
      _updateNodePosition(node, pos, shiftX, shiftY);
      minX = min(minX, x);
      minY = min(minY, y);
      maxX = max(maxX, x);
      maxY = max(maxY, y);

      // Recursively position children
      _positionChildren(node, pos, calculatedPositions, graph, shiftX, shiftY, (
        newPos,
      ) {
        minX = min(minX, newPos.dx);
        minY = min(minY, newPos.dy);
        maxX = max(maxX, newPos.dx);
        maxY = max(maxY, newPos.dy);
      });
    }

    // Calculate the size needed for the graph based on min/max coordinates
    final width = max(0.0, maxX - minX);
    final height = max(0.0, maxY - minY);
    final size = Size(width + 100, height + 100); // Add padding

    print("Circular Layout calculated size: $size");
    return size;
  }

  // Recursive function to position children
  void _positionChildren(
    Node parentNode,
    Offset parentPosition,
    Map<int, Offset> calculatedPositions,
    Graph displayedGraph, // Use displayed graph to find *visible* children
    double shiftX,
    double shiftY,
    void Function(Offset) updateBounds, // Callback to update min/max XY
  ) {
    final parentData = parentNode.key?.value as MindMapNode?;
    if (parentData == null) return;

    // Find direct children *in the displayed graph*
    final children = displayedGraph.successorsOf(parentNode).toList();
    if (children.isEmpty) return;

    final currentLevel = parentData.level + 1;
    final radius = currentLevel * layerDistance;

    // --- Determine Angle Calculation Strategy ---
    // Option A: Base angle on parent's angle (direct line out) + spread
    // Option B: Distribute evenly around the circle (might cause crossovers)
    // Let's try Option A initially. Find parent's angle relative to *its* parent.

    double parentAngle = atan2(
      parentPosition.dy,
      parentPosition.dx,
    ); // Angle of parent relative to origin (0,0)
    // For levels > 1, we might want angle relative to grandparent? This gets complex.
    // Simplification: Use parent's absolute angle for now.

    final double totalAngleSpan =
        pi /
        (1 +
            (currentLevel *
                0.5)); // Reduce span as levels increase? Needs tuning. Or use nodeDistance?
    final double angleStep =
        children.length > 1 ? totalAngleSpan / (children.length - 1) : 0;
    final double startAngle = parentAngle - (totalAngleSpan / 2);

    // Alternative using node distance: Calculate circumference, distribute nodes
    // final circumference = 2 * pi * radius;
    // final requiredSpacingForAllNodes = children.length * nodeDistanceWithinLayer;
    // final anglePerNode = (requiredSpacingForAllNodes / circumference) * 2 * pi / children.length; // Angle needed per node

    for (int i = 0; i < children.length; i++) {
      final childNode = children[i];
      final childData = childNode.key?.value as MindMapNode?;
      if (childData == null) continue;

      // Avoid recalculating if already positioned via another path (though less likely in pure tree)
      if (calculatedPositions.containsKey(childData.id)) {
        // Node already positioned, just ensure edge exists visually if needed
        continue;
      }

      // Calculate angle for this child
      final angle =
          children.length == 1 ? parentAngle : startAngle + (i * angleStep);
      // final angle = parentAngle + (i - (children.length - 1) / 2) * anglePerNode; // Using distance logic

      final x = radius * cos(angle);
      final y = radius * sin(angle);
      final pos = Offset(x, y); // Position relative to origin (0,0)
      // If we wanted relative to parent: pos = parentPosition + Offset(deltaX, deltaY);

      calculatedPositions[childData.id] = pos;
      _updateNodePosition(childNode, pos, shiftX, shiftY);
      updateBounds(pos); // Update overall bounds

      // Recurse for grandchildren
      _positionChildren(
        childNode,
        pos,
        calculatedPositions,
        displayedGraph,
        shiftX,
        shiftY,
        updateBounds,
      );
    }
  }

  // Helper to set the node's position for graphview
  void _updateNodePosition(
    Node node,
    Offset position,
    double shiftX,
    double shiftY,
  ) {
    node.position = position; // Store the calculated absolute position
    node.x = position.dx + shiftX; // Apply shift for graphview canvas
    node.y = position.dy + shiftY;
  }
}
