enum NodeType { dealer, client }

enum NodeStatus { active, potential }

class NetworkNode {
  final String id;
  final String name;
  final NodeType type;
  final NodeStatus status;
  final int totalOrders;
  final double totalSpent;
  final bool isVip;
  final double distance;

  const NetworkNode({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.totalOrders,
    required this.totalSpent,
    required this.isVip,
    required this.distance,
  });
}
