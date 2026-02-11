import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/network_node.dart';

void main() {
  group('NodeType enum', () {
    test('has all expected values', () {
      expect(NodeType.values, [NodeType.dealer, NodeType.client]);
    });
  });

  group('NodeStatus enum', () {
    test('has all expected values', () {
      expect(NodeStatus.values, [NodeStatus.active, NodeStatus.potential]);
    });
  });

  group('NetworkNode', () {
    test('constructor sets all fields correctly', () {
      const node = NetworkNode(
        id: 'node-001',
        name: 'Pizzeria Da Michele',
        type: NodeType.dealer,
        status: NodeStatus.active,
        totalOrders: 45,
        totalSpent: 1250.0,
        isVip: true,
        distance: 2.5,
      );

      expect(node.id, 'node-001');
      expect(node.name, 'Pizzeria Da Michele');
      expect(node.type, NodeType.dealer);
      expect(node.status, NodeStatus.active);
      expect(node.totalOrders, 45);
      expect(node.totalSpent, 1250.0);
      expect(node.isVip, true);
      expect(node.distance, 2.5);
    });

    test('client type with potential status', () {
      const node = NetworkNode(
        id: 'node-002',
        name: 'Mario Rossi',
        type: NodeType.client,
        status: NodeStatus.potential,
        totalOrders: 0,
        totalSpent: 0,
        isVip: false,
        distance: 5.0,
      );

      expect(node.type, NodeType.client);
      expect(node.status, NodeStatus.potential);
      expect(node.isVip, false);
    });
  });
}
