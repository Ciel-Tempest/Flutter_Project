// lib/models/mind_map_node.dart
import 'package:flutter/material.dart';

class MindMapNode {
  final int id; // Unique ID for the graph library
  final String label;
  final int level; // 1: Customer Need, 2: Product, etc.
  final Map<String, dynamic> originalData; // Store the row data
  // Potentially add styling info later (color, size)

  MindMapNode({
    required this.id,
    required this.label,
    required this.level,
    required this.originalData,
  });

  // Override equals and hashCode for comparison if needed, especially for IDs
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MindMapNode && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MindMapNode(id: $id, label: "$label", level: $level)';
  }
}