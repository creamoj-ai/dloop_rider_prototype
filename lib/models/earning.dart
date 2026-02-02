enum EarningType { delivery, network, market }

enum EarningStatus { completed, pending, cancelled }

class Earning {
  final String id;
  final EarningType type;
  final String description;
  final double amount;
  final DateTime dateTime;
  final EarningStatus status;

  const Earning({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.dateTime,
    required this.status,
  });
}
