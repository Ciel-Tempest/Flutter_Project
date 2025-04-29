// lib/providers/graph_data_provider.dart
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:excel/excel.dart';
import 'package:graphview/GraphView.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/mind_map_node.dart';
//import 'dart:collection'; // For SplayTreeMap if needed

part 'graph_data_provider.g.dart';

// --- Constants for Column Names ---
const String colCustomerNeed = 'Customer need';
const String colProduct = 'Product';
const String colStage = 'Stage';
const String colMacroJourneyText =
    'Macro Journey'; // Text column (use G for Macro Journey name)
const String colMacroJourneyId =
    '# Macro Journey'; // ID column (use F for Macro Journey ID)
const String colMicroJourneyText =
    'Micro Journey'; // Text column (use I for Micro Journey name)
const String colMicroJourneyId =
    '# Micro Journey'; // ID column (use H for Micro Journey ID)
const String colSubJourneyText =
    'Sub Journey'; // Text column (use K for Sub Journey name)
const String colMicroSubId =
    'Micro&Sub'; // Combined ID column (use L for unique Leaf ID)
// --- End Constants ---

// Helper to get cell value as String?
String? _cellValue(List<Data?> row, int index) {
  if (index >= 0 && index < row.length && row[index]?.value != null) {
    var value = row[index]!.value;
    // Handle potential numeric values if IDs are read as numbers
    if (value is double) {
      return value.toInt().toString();
    }
    return value.toString().trim();
  }
  return null;
}

// Helper to create a unique ID for a node based on its path
String _createPathId(String? parentPath, String? currentLabel) {
  if (currentLabel == null || currentLabel.isEmpty) return parentPath ?? '';
  return parentPath == null || parentPath.isEmpty
      ? currentLabel
      : '$parentPath > $currentLabel';
}

@riverpod
Future<Graph> fullGraph(FullGraphRef ref) async {
  // Renamed provider
  print("Starting Excel processing...");
  final ByteData data = await rootBundle.load('assets/Input_data.xlsx');
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final excel = Excel.decodeBytes(bytes);
  final sheetName = excel.tables.keys.first;
  final sheet = excel.tables[sheetName]!;

  // More robust header mapping (find columns by name)
  final headerRow = sheet.rows.firstWhere(
    (row) => row.any((cell) => cell?.value != null),
  );
  final Map<String, int> colIndices = {};
  for (int i = 0; i < headerRow.length; i++) {
    final header = _cellValue(headerRow, i);
    if (header != null && header.isNotEmpty) {
      colIndices[header] = i;
    }
  }
  // Add manual mapping for '#' columns if names are inconsistent
  colIndices.putIfAbsent(colMacroJourneyId, () => 5); // Assuming F is index 5
  colIndices.putIfAbsent(colMicroJourneyId, () => 8); // Assuming H is index 8
  colIndices.putIfAbsent(colMicroSubId, () => 11); // Assuming L is index 11

  final Graph graph = Graph();
  // Using a map to store nodes: Key is the unique path string, Value is the Node
  final Map<String, Node> allNodes = {};
  int nodeIdCounter = 1;

  // Skip header row (start from index 1, or find first data row)
  for (var i = 1; i < sheet.maxRows; i++) {
    final row = sheet.row(i);
    if (row.every(
      (cell) =>
          cell == null || cell.value == null || cell.value.toString().isEmpty,
    )) {
      continue; // Skip entirely empty rows
    }

    // Extract data using helper and mapped indices
    final customerNeed = _cellValue(row, colIndices[colCustomerNeed] ?? -1);

    // --- FILTERING ---
    if (customerNeed == null ||
        customerNeed.isEmpty ||
        customerNeed == "New customer journeys to be added - FY25") {
      print("Skipping row $i due to filter or empty Customer Need.");
      continue; // Skip rows without customer need or the specific one to ignore
    }

    final product = _cellValue(row, colIndices[colProduct] ?? -1);
    final stage = _cellValue(row, colIndices[colStage] ?? -1);
    // Use Text columns for labels, ID columns if needed for uniqueness/data
    final macroJourneyLabel = _cellValue(
      row,
      colIndices[colMacroJourneyText] ?? -1,
    );
    final microJourneyLabel = _cellValue(
      row,
      colIndices[colMicroJourneyText] ?? -1,
    );
    final subJourneyLabel = _cellValue(
      row,
      colIndices[colSubJourneyText] ?? -1,
    );

    // final macroJourneyId = _cellValue(row, colIndices[colMacroJourneyId] ?? -1);
    // final microJourneyId = _cellValue(row, colIndices[colMicroJourneyId] ?? -1);
    // final microSubId = _cellValue(row, colIndices[colMicroSubId] ?? -1);

    // Create the full row data map for the MindMapNode
    final Map<String, dynamic> originalData = {};
    colIndices.forEach((key, index) {
      originalData[key] = _cellValue(row, index);
    });

    Node? parentNode;
    String currentPathId = '';

    // --- Function to add/get node and create edge ---
    Node getNodeAndAddEdge(
      String? label,
      int level,
      String parentPathId,
      Node? currentParent,
    ) {
      if (label == null || label.isEmpty) {
        if (currentParent == null)
          throw Exception("Cannot proceed without parent for level $level");
        return currentParent; // No node at this level, return parent
      }

      final pathId = _createPathId(parentPathId, label);
      if (!allNodes.containsKey(pathId)) {
        // Node doesn't exist, create it
        final newNodeData = MindMapNode(
          id: nodeIdCounter++,
          label: label,
          level: level,
          originalData: originalData, // Store data from this specific row
        );
        final graphNode = Node.Id(newNodeData);
        allNodes[pathId] = graphNode;
        graph.addNode(graphNode); // Add to the main graph object

        // Add edge if parent exists (should always exist after level 1)
        if (currentParent != null) {
          print(
            "Adding edge: ${(currentParent.key?.value as MindMapNode).label} -> ${newNodeData.label}",
          );
          graph.addEdge(currentParent, graphNode);
        } else if (level != 1) {
          print("Warning: Parent is null for node $label at level $level");
        }
      } else {
        // Node already exists, maybe update data if needed? For now, just retrieve.
        // Be careful here: which row's 'originalData' should the node hold if multiple paths lead to it?
        // Simplest approach: store data from the *first* time it was encountered.
      }
      return allNodes[pathId]!;
    }

    // --- Process Hierarchy ---
    try {
      // Level 1: Customer Need
      parentNode = getNodeAndAddEdge(customerNeed, 1, '', null);
      currentPathId = _createPathId('', customerNeed);

      // Level 2: Product
      parentNode = getNodeAndAddEdge(product, 2, currentPathId, parentNode);
      currentPathId = _createPathId(currentPathId, product);

      // Level 3: Stage
      parentNode = getNodeAndAddEdge(stage, 3, currentPathId, parentNode);
      currentPathId = _createPathId(currentPathId, stage);

      // Level 4: Macro Journey
      // Use ID in path if available and meaningful? Or stick to label for path ID?
      // Let's stick to label for path ID for consistency, but store the ID in originalData.
      parentNode = getNodeAndAddEdge(
        macroJourneyLabel,
        4,
        currentPathId,
        parentNode,
      );
      currentPathId = _createPathId(currentPathId, macroJourneyLabel);

      // Level 5: Micro Journey
      parentNode = getNodeAndAddEdge(
        microJourneyLabel,
        5,
        currentPathId,
        parentNode,
      );
      currentPathId = _createPathId(currentPathId, microJourneyLabel);

      // Level 6: Sub Journey (Optional)
      if (subJourneyLabel != null && subJourneyLabel.isNotEmpty) {
        parentNode = getNodeAndAddEdge(
          subJourneyLabel,
          6,
          currentPathId,
          parentNode,
        );
        // currentPathId = _createPathId(currentPathId, subJourneyLabel); // Path ends here if sub-journey exists
      }
    } catch (e) {
      print("Error processing row $i: $e");
      continue; // Skip to next row on error
    }
  }

  print(
    "Excel processing finished. ${graph.nodeCount} nodes, ${graph.edges.length} edges.",
  );
  if (graph.nodes
      .where((n) => (n.key?.value as MindMapNode).level == 1)
      .isEmpty) {
    print("WARNING: No Level 1 nodes were created!");
  }
  return graph;
}
