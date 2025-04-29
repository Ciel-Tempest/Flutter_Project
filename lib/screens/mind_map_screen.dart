// lib/screens/mind_map_screen.dart
import 'package:customer_atlas_mindmap/providers/graph_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import '../providers/graph_display_provider.dart'; // Uses the state notifier
import '../models/mind_map_node.dart';

class MindMapScreen extends ConsumerWidget {
  const MindMapScreen({super.key});

  // Define the Active Color
  final Color activeColor = const Color(0xFFFFD700); // Golden color

  // Define the color palette for different levels, considering active state
  Color getNodeColor(int level, bool isActive, BuildContext context) {
    if (isActive) return activeColor; // Prioritize active color
    switch (level) {
      case 1:
        return const Color.fromARGB(255, 141, 159, 25)!; // Purple
      case 2:
        return const Color.fromARGB(255, 211, 69, 13); // Dark Pink/Magenta
      case 3:
        return const Color.fromARGB(255, 222, 158, 22)!; // Indigo
      case 4:
        return const Color.fromARGB(255, 228, 232, 27)!; // Dark Blue
      case 5:
        return Colors.blue[500]!; // Blue
      case 6:
        return Colors.lightBlue[400]!; // Sky Blue
      default:
        return const Color.fromARGB(255, 135, 19, 88)!; // Fallback
    }
  }

  // Define border color based on level, expansion, and active state
  Color getBorderColor(
    int level,
    bool isExpanded,
    bool isActive,
    BuildContext context,
  ) {
    if (isActive)
      return Colors.orangeAccent[400]!; // Distinct border for active
    // Use expansion color for border if expanded and not active
    if (isExpanded) return Theme.of(context).colorScheme.secondary;
    // Otherwise, maybe a subtle border based on node color or just a default
    // return getNodeColor(level, false, context).withOpacity(0.8); // Slightly transparent version of node color
    return Colors
        .white54; // Alternative: Simple white border for inactive collapsed
  }

  // Define text color (ensure contrast with background)
  Color getTextColor(
    int level,
    bool isExpanded,
    bool isActive,
    BuildContext context,
  ) {
    Color bgColor;
    // Determine the background color this text will sit on
    if (isActive) {
      bgColor = activeColor;
    } else if (isExpanded) {
      // Use expansion color only if not active
      bgColor = Theme.of(context).colorScheme.secondary;
    } else {
      bgColor = getNodeColor(level, false, context);
    }

    // Use ThemeData's estimate for brightness to choose black or white text
    return ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark
        ? Colors.white.withOpacity(
          0.95,
        ) // Slightly more opaque white for dark backgrounds
        : Colors.black.withOpacity(0.9); // Dark text for light backgrounds
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the state from the GraphDisplay notifier
    final graphDisplayStateAsync = ref.watch(graphDisplayProvider);

    // Use FruchtermanReingold for force-directed layout
    final algorithm = FruchtermanReingoldAlgorithm(
      iterations: 300,
    ); // Stick with force-directed

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Atlas Mind Map'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: graphDisplayStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          print("Error in UI: $err\n$stack");
          return Center(child: Text('Error building graph view: $err'));
        },
        data: (graphDisplayState) {
          // Data is GraphDisplayState
          final graphToDisplay = graphDisplayState.displayedGraph;
          final expandedNodeIds = graphDisplayState.expandedNodeIds;
          final activeNodeId =
              graphDisplayState.lastTappedNodeId; // <<< Get the active ID

          if (graphToDisplay.nodeCount == 0) {
            // Handle case where initial nodes might not be loaded yet or filtering failed
            final fullGraphFuture = ref.read(fullGraphProvider.future);
            return FutureBuilder<Graph>(
              future: fullGraphFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Text('Loading initial data...'));
                } else if (snapshot.hasError || snapshot.data?.nodeCount == 0) {
                  return const Center(child: Text('No nodes found in data.'));
                } else {
                  return const Center(child: Text('Initializing display...'));
                }
              },
            );
          }

          return InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(200), // Keep generous margin
            minScale: 0.05,
            maxScale: 2.5,
            child: GraphView(
              graph: graphToDisplay,
              algorithm: algorithm, // Use FruchtermanReingold
              paint:
                  Paint()
                    ..color = Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.6)
                    ..strokeWidth = 1.2
                    ..style = PaintingStyle.stroke,
              builder: (Node node) {
                // Build the widget for each node
                final nodeData = node.key?.value as MindMapNode?;
                if (nodeData == null) return Container(); // Should not happen

                // --- Determine Node State ---
                bool isExpanded = expandedNodeIds.contains(nodeData.id);
                bool isActive =
                    nodeData.id ==
                    activeNodeId; // <<< Check if this node is active

                // --- Get Dynamic Colors ---
                Color nodeColor = getNodeColor(
                  nodeData.level,
                  isActive,
                  context,
                );
                Color borderColor = getBorderColor(
                  nodeData.level,
                  isExpanded,
                  isActive,
                  context,
                );
                Color textColor = getTextColor(
                  nodeData.level,
                  isExpanded,
                  isActive,
                  context,
                );

                // --- Determine Container Background Color ---
                Color containerColor =
                    isActive
                        ? activeColor // Active node is always golden
                        : (isExpanded
                            ? Theme.of(context)
                                .colorScheme
                                .secondary // Expanded (not active) is teal
                            : nodeColor); // Collapsed (not active) uses level color

                return GestureDetector(
                  onTap: () {
                    print(
                      "Tapped on: ${nodeData.label} (Level: ${nodeData.level}, ID: ${nodeData.id})",
                    );
                    // Call the toggle method in the notifier
                    ref.read(graphDisplayProvider.notifier).toggleNode(node);
                  },
                  child: AnimatedContainer(
                    // Use AnimatedContainer for smooth transitions
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ), // Smaller padding
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 20,
                    ), // Min size
                    decoration: BoxDecoration(
                      color:
                          containerColor, // Use the calculated container color
                      borderRadius: BorderRadius.circular(
                        20,
                      ), // Consistent rounding
                      border: Border.all(
                        color: borderColor,
                        width:
                            isActive
                                ? 2.0
                                : 1.5, // <<< Thicker border for active node
                      ),
                      boxShadow: [
                        BoxShadow(
                          // Shadow color based on the *actual* container color
                          color: containerColor.withOpacity(
                            isActive ? 0.5 : 0.3,
                          ), // <<< Brighter shadow for active
                          blurRadius: isActive ? 6 : 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      // Center text
                      child: Text(
                        nodeData.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textColor, // Dynamic text color
                          fontWeight:
                              isActive
                                  ? FontWeight.bold
                                  : FontWeight.w500, // <<< Bold text for active
                          fontSize: 10, // Smaller font size
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis, // Handle overflow
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
