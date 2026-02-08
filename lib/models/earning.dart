enum EarningType { delivery, network, market }

enum EarningStatus { completed, pending, cancelled }

class Earning {
  final String id;
  final EarningType type;
  final String description;
  final double amount;
  final DateTime dateTime;
  final EarningStatus status;
  final String? orderId;

  const Earning({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.dateTime,
    required this.status,
    this.orderId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'description': description,
    'amount': amount,
    'date_time': dateTime.toIso8601String(),
    'status': status.name,
    'order_id': orderId,
  };

  factory Earning.fromJson(Map<String, dynamic> json) => Earning(
    id: json['id'] as String,
    type: EarningType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => EarningType.delivery,
    ),
    description: json['description'] as String? ?? '',
    amount: (json['amount'] as num).toDouble(),
    dateTime: DateTime.parse(json['date_time'] as String),
    status: EarningStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => EarningStatus.completed,
    ),
    orderId: json['order_id'] as String?,
  );
}
