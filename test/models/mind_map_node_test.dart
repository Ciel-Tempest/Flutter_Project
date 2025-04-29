import 'package:customer_atlas_mindmap/models/mind_map_node.dart'; // Import your model
import 'package:test/test.dart';

void main() {
  group('MindMapNode', () {
    test('Constructor sets properties correctly', () {
      final Map<String, dynamic> testData = {'colA': 'valueA', 'colB': 123};
      final node = MindMapNode(
        id: 101,
        label: 'Test Node',
        level: 3,
        originalData: testData,
      );

      expect(node.id, 101);
      expect(node.label, 'Test Node');
      expect(node.level, 3);
      expect(node.originalData, equals(testData));
    });

    test('Equality operator works based on ID', () {
      final node1a = MindMapNode(
        id: 1,
        label: 'Node A',
        level: 1,
        originalData: {},
      );
      final node1b = MindMapNode(
        id: 1,
        label: 'Node A Duplicate ID',
        level: 2,
        originalData: {},
      );
      final node2 = MindMapNode(
        id: 2,
        label: 'Node B',
        level: 1,
        originalData: {},
      );

      expect(node1a == node1b, isTrue); // Same ID means equals
      expect(
        node1a.hashCode == node1b.hashCode,
        isTrue,
      ); // Same ID means same hashcode

      expect(node1a == node2, isFalse);
      expect(node1a.hashCode == node2.hashCode, isFalse);
    });

    test('toString provides useful representation', () {
      final node = MindMapNode(
        id: 5,
        label: 'My Label',
        level: 2,
        originalData: {},
      );
      expect(
        node.toString(),
        'MindMapNode(id: 5, label: "My Label", level: 2)',
      );
    });
  });
}
