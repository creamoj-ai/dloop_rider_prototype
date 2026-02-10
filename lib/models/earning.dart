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
    'type': _typeToDb(type),
    'description': description,
    'amount': amount,
    'processed_at': dateTime.toIso8601String(),
    'status': status.name,
  };

  factory Earning.fromJson(Map<String, dynamic> json) => Earning(
    id: json['id']?.toString() ?? '',
    type: _typeFromDb(json['type'] as String? ?? ''),
    description: json['description'] as String? ?? '',
    amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
    dateTime: DateTime.tryParse(
      json['processed_at'] as String? ?? json['date_time'] as String? ?? '',
    ) ?? DateTime.now(),
    status: EarningStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => EarningStatus.completed,
    ),
    orderId: json['order_id'] as String?,
  );

  // DB uses order_earning/commission/market_sale/bonus/tip
  static String _typeToDb(EarningType type) {
    switch (type) {
      case EarningType.delivery: return 'order_earning';
      case EarningType.network: return 'commission';
      case EarningType.market: return 'market_sale';
    }
  }

  static EarningType _typeFromDb(String dbType) {
    switch (dbType) {
      case 'order_earning': return EarningType.delivery;
      case 'commission': return EarningType.network;
      case 'market_sale': return EarningType.market;
      case 'bonus': return EarningType.network;
      case 'tip': return EarningType.delivery;
      default: return EarningType.delivery;
    }
  }
}
