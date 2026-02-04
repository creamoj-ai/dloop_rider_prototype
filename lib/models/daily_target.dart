/// Daily Target Model
/// Rappresenta l'obiettivo giornaliero del rider e il progresso.

class DailyTarget {
  final double targetAmount;
  final double currentAmount;
  final int ordersCompleted;
  final DateTime date;

  const DailyTarget({
    this.targetAmount = 80.0, // €80 obiettivo default
    this.currentAmount = 0,
    this.ordersCompleted = 0,
    required this.date,
  });

  /// Progresso da 0.0 a 1.0
  double get progress => targetAmount > 0
      ? (currentAmount / targetAmount).clamp(0.0, 1.0)
      : 0.0;

  /// Percentuale completamento (0-100)
  int get progressPercent => (progress * 100).round();

  /// Quanto manca per raggiungere l'obiettivo
  double get remaining => (targetAmount - currentAmount).clamp(0.0, targetAmount);

  /// Obiettivo raggiunto?
  bool get isComplete => currentAmount >= targetAmount;

  /// Media guadagno per ordine
  double get avgPerOrder => ordersCompleted > 0
      ? currentAmount / ordersCompleted
      : 0.0;

  /// Stima ordini necessari per completare
  int get estimatedOrdersToComplete {
    if (isComplete || avgPerOrder <= 0) return 0;
    return (remaining / avgPerOrder).ceil();
  }

  /// Aggiunge un nuovo guadagno e ritorna una nuova istanza
  DailyTarget addEarning(double amount) {
    return DailyTarget(
      targetAmount: targetAmount,
      currentAmount: currentAmount + amount,
      ordersCompleted: ordersCompleted + 1,
      date: date,
    );
  }

  /// Resetta il target per un nuovo giorno
  DailyTarget resetForNewDay() {
    return DailyTarget(
      targetAmount: targetAmount,
      currentAmount: 0,
      ordersCompleted: 0,
      date: DateTime.now(),
    );
  }

  /// Crea una copia con valori modificati
  DailyTarget copyWith({
    double? targetAmount,
    double? currentAmount,
    int? ordersCompleted,
    DateTime? date,
  }) {
    return DailyTarget(
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      ordersCompleted: ordersCompleted ?? this.ordersCompleted,
      date: date ?? this.date,
    );
  }

  /// Per debug/logging
  @override
  String toString() {
    return 'DailyTarget(€$currentAmount/€$targetAmount, $ordersCompleted orders, $progressPercent%)';
  }
}
