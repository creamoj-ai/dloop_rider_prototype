import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../models/daily_target.dart';
import '../services/rush_hour_service.dart';

/// Stato globale per i guadagni del rider
class EarningsState {
  final DailyTarget dailyTarget;
  final List<Order> todayOrders;
  final bool isOnline;
  final Order? activeOrder;
  final double totalKmToday;

  const EarningsState({
    required this.dailyTarget,
    this.todayOrders = const [],
    this.isOnline = false,
    this.activeOrder,
    this.totalKmToday = 0,
  });

  // === Getters utili ===

  /// Guadagno totale di oggi
  double get todayTotal => dailyTarget.currentAmount;

  /// Numero ordini completati oggi
  int get ordersCount => todayOrders.where((o) => o.status == OrderStatus.delivered).length;

  /// Media guadagno per ordine
  double get avgPerOrder => ordersCount > 0 ? todayTotal / ordersCount : 0;

  /// Guadagno orario stimato (basato sulle ultime 2 ore)
  double get hourlyRate {
    if (todayOrders.isEmpty) return 0;

    final now = DateTime.now();
    final twoHoursAgo = now.subtract(const Duration(hours: 2));

    final recentOrders = todayOrders.where((o) =>
      o.deliveredAt != null && o.deliveredAt!.isAfter(twoHoursAgo)
    ).toList();

    if (recentOrders.isEmpty) return avgPerOrder * 2; // Stima fallback

    final recentTotal = recentOrders.fold(0.0, (sum, o) => sum + o.totalEarning);
    final oldestDelivery = recentOrders.map((o) => o.deliveredAt!).reduce(
      (a, b) => a.isBefore(b) ? a : b
    );

    final hoursWorked = now.difference(oldestDelivery).inMinutes / 60;
    return hoursWorked > 0 ? recentTotal / hoursWorked : recentTotal;
  }

  /// È in rush hour?
  bool get isRushHour => RushHourService.isRushHourNow();

  /// Moltiplicatore corrente
  double get currentMultiplier => RushHourService.getCurrentMultiplier();

  /// Ha un ordine attivo?
  bool get hasActiveOrder => activeOrder != null;

  /// Breakdown guadagni di oggi
  Map<String, double> get todayBreakdown {
    double base = 0, bonus = 0, tips = 0, rush = 0;

    for (var order in todayOrders.where((o) => o.status == OrderStatus.delivered)) {
      base += order.baseEarning;
      bonus += order.bonusEarning;
      tips += order.tipAmount;
      rush += order.rushBonus;
    }

    return {
      'base': base,
      'bonus': bonus,
      'tips': tips,
      'rush': rush,
      'total': base + bonus + tips + rush,
    };
  }

  /// Crea una copia con valori modificati
  EarningsState copyWith({
    DailyTarget? dailyTarget,
    List<Order>? todayOrders,
    bool? isOnline,
    Order? activeOrder,
    double? totalKmToday,
    bool clearActiveOrder = false,
  }) {
    return EarningsState(
      dailyTarget: dailyTarget ?? this.dailyTarget,
      todayOrders: todayOrders ?? this.todayOrders,
      isOnline: isOnline ?? this.isOnline,
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      totalKmToday: totalKmToday ?? this.totalKmToday,
    );
  }
}

/// Notifier per gestire lo stato dei guadagni
class EarningsNotifier extends StateNotifier<EarningsState> {
  EarningsNotifier() : super(EarningsState(
    dailyTarget: DailyTarget(date: DateTime.now()),
  )) {
    // Carica dati mock per demo
    _loadDemoData();
  }

  /// Carica ordini demo per testare UI con vari stati
  void _loadDemoData() {
    // Ordine 1 - CONSEGNATO - mattina
    _addDemoOrder(
      restaurantName: 'La Piadineria',
      customerAddress: 'Via Dante 23',
      distanceKm: 1.8,
      tipAmount: 0.50,
      minutesAgo: 180,
      status: OrderStatus.delivered,
    );

    // Ordine 2 - CONSEGNATO - pranzo rush hour
    _addDemoOrder(
      restaurantName: 'Rossopomodoro',
      customerAddress: 'Piazza Duomo 1',
      distanceKm: 2.3,
      tipAmount: 1.00,
      minutesAgo: 120,
      forceRush: true,
      status: OrderStatus.delivered,
    );

    // Ordine 3 - RIFIUTATO
    _addDemoOrder(
      restaurantName: 'KFC',
      customerAddress: 'Via Padova 118',
      distanceKm: 4.5,
      minutesAgo: 90,
      status: OrderStatus.cancelled,
    );

    // Ordine 4 - CONSEGNATO - pomeriggio
    _addDemoOrder(
      restaurantName: 'Sushi Zen',
      customerAddress: 'Corso Italia 88',
      distanceKm: 3.1,
      minutesAgo: 60,
      status: OrderStatus.delivered,
    );

    // Ordine 5 - RITIRATO (in consegna)
    _addDemoOrder(
      restaurantName: 'Pizzeria Da Mario',
      customerAddress: 'Via Roma 15',
      distanceKm: 1.5,
      minutesAgo: 15,
      forceRush: true,
      status: OrderStatus.pickedUp,
    );

    // Ordine 6 - ACCETTATO (da ritirare)
    _addDemoOrder(
      restaurantName: 'Burger King',
      customerAddress: 'Corso Buenos Aires 45',
      distanceKm: 2.0,
      minutesAgo: 5,
      status: OrderStatus.accepted,
    );

    // Ordine 7 - DA ACCETTARE (pending)
    _addDemoOrder(
      restaurantName: 'Poke House',
      customerAddress: 'Via Montenapoleone 8',
      distanceKm: 1.2,
      minutesAgo: 2,
      status: OrderStatus.pending,
    );
  }

  /// Aggiunge ordine demo con timestamp e stato simulati
  void _addDemoOrder({
    required String restaurantName,
    required String customerAddress,
    required double distanceKm,
    double tipAmount = 0,
    int minutesAgo = 0,
    bool forceRush = false,
    OrderStatus status = OrderStatus.delivered,
  }) {
    final timestamp = DateTime.now().subtract(Duration(minutes: minutesAgo));
    final rushMultiplier = forceRush ? 2.0 : 1.0;
    final baseEarning = distanceKm * Order.ratePerKm;

    final order = Order(
      id: 'demo_${DateTime.now().millisecondsSinceEpoch}_$minutesAgo',
      restaurantName: restaurantName,
      customerAddress: customerAddress,
      distanceKm: distanceKm,
      baseEarning: baseEarning,
      tipAmount: tipAmount,
      rushMultiplier: rushMultiplier,
      status: status,
      createdAt: timestamp.subtract(const Duration(minutes: 15)),
      acceptedAt: status.index >= OrderStatus.accepted.index ? timestamp.subtract(const Duration(minutes: 10)) : null,
      pickedUpAt: status.index >= OrderStatus.pickedUp.index ? timestamp.subtract(const Duration(minutes: 5)) : null,
      deliveredAt: status == OrderStatus.delivered ? timestamp : null,
    );

    final updatedOrders = [...state.todayOrders, order];

    // Solo gli ordini consegnati contano per il target
    final updatedTarget = status == OrderStatus.delivered
        ? state.dailyTarget.addEarning(order.totalEarning)
        : state.dailyTarget;
    final updatedKm = status == OrderStatus.delivered
        ? state.totalKmToday + order.distanceKm
        : state.totalKmToday;

    state = state.copyWith(
      todayOrders: updatedOrders,
      dailyTarget: updatedTarget,
      totalKmToday: updatedKm,
    );
  }

  /// Vai online/offline
  void toggleOnline() {
    state = state.copyWith(isOnline: !state.isOnline);
  }

  /// Imposta stato online
  void setOnline(bool online) {
    state = state.copyWith(isOnline: online);
  }

  /// Accetta un nuovo ordine
  void acceptOrder(Order order) {
    final acceptedOrder = order.copyWithStatus(OrderStatus.accepted);
    state = state.copyWith(activeOrder: acceptedOrder);
  }

  /// Segna ordine come ritirato
  void pickupOrder() {
    if (state.activeOrder == null) return;
    final pickedUpOrder = state.activeOrder!.copyWithStatus(OrderStatus.pickedUp);
    state = state.copyWith(activeOrder: pickedUpOrder);
  }

  /// Completa la consegna
  void completeDelivery({double? tipAmount}) {
    if (state.activeOrder == null) return;

    var completedOrder = state.activeOrder!.copyWithStatus(OrderStatus.delivered);

    // Aggiungi mancia se presente
    if (tipAmount != null && tipAmount > 0) {
      completedOrder = completedOrder.addTip(tipAmount);
    }

    // Aggiorna lista ordini
    final updatedOrders = [...state.todayOrders, completedOrder];

    // Aggiorna target giornaliero
    final updatedTarget = state.dailyTarget.addEarning(completedOrder.totalEarning);

    // Aggiorna km totali
    final updatedKm = state.totalKmToday + completedOrder.distanceKm;

    state = state.copyWith(
      todayOrders: updatedOrders,
      dailyTarget: updatedTarget,
      totalKmToday: updatedKm,
      clearActiveOrder: true,
    );
  }

  /// Annulla ordine attivo
  void cancelActiveOrder() {
    if (state.activeOrder == null) return;
    final cancelledOrder = state.activeOrder!.copyWithStatus(OrderStatus.cancelled);
    final updatedOrders = [...state.todayOrders, cancelledOrder];

    state = state.copyWith(
      todayOrders: updatedOrders,
      clearActiveOrder: true,
    );
  }

  /// Simula un ordine completato (per testing/demo)
  void simulateCompletedOrder({
    required String restaurantName,
    required String customerAddress,
    required double distanceKm,
    double bonusEarning = 0,
    double tipAmount = 0,
  }) {
    final order = Order.create(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}',
      restaurantName: restaurantName,
      customerAddress: customerAddress,
      distanceKm: distanceKm,
      bonusEarning: bonusEarning,
      tipAmount: tipAmount,
    ).copyWithStatus(OrderStatus.delivered);

    final updatedOrders = [...state.todayOrders, order];
    final updatedTarget = state.dailyTarget.addEarning(order.totalEarning);
    final updatedKm = state.totalKmToday + order.distanceKm;

    state = state.copyWith(
      todayOrders: updatedOrders,
      dailyTarget: updatedTarget,
      totalKmToday: updatedKm,
    );
  }

  /// Modifica il target giornaliero
  void setDailyTarget(double newTarget) {
    state = state.copyWith(
      dailyTarget: state.dailyTarget.copyWith(targetAmount: newTarget),
    );
  }

  /// Reset per nuovo giorno
  void resetForNewDay() {
    state = EarningsState(
      dailyTarget: DailyTarget(date: DateTime.now()),
      isOnline: state.isOnline,
    );
  }

  /// Carica dati iniziali (mock per ora)
  void loadMockData() {
    // Simula alcuni ordini completati
    simulateCompletedOrder(
      restaurantName: 'Pizzeria Napoli',
      customerAddress: 'Via Roma 15',
      distanceKm: 2.3,
      tipAmount: 2.0,
    );
    simulateCompletedOrder(
      restaurantName: 'Sushi Zen',
      customerAddress: 'Corso Italia 42',
      distanceKm: 3.1,
      bonusEarning: 1.5,
    );
    simulateCompletedOrder(
      restaurantName: 'Burger House',
      customerAddress: 'Via Garibaldi 8',
      distanceKm: 1.8,
      tipAmount: 1.0,
    );
  }
}

// === PROVIDERS ===

/// Provider principale per lo stato dei guadagni
final earningsProvider = StateNotifierProvider<EarningsNotifier, EarningsState>(
  (ref) => EarningsNotifier(),
);

/// Provider per controllare se è rush hour (si aggiorna automaticamente)
final isRushHourProvider = Provider<bool>((ref) {
  return RushHourService.isRushHourNow();
});

/// Provider per il moltiplicatore corrente
final currentMultiplierProvider = Provider<double>((ref) {
  return RushHourService.getCurrentMultiplier();
});

/// Provider per i minuti alla prossima rush hour
final minutesToRushHourProvider = Provider<int?>((ref) {
  return RushHourService.minutesToNextRushHour();
});

/// Provider per il breakdown guadagni di oggi
final todayBreakdownProvider = Provider<Map<String, double>>((ref) {
  final state = ref.watch(earningsProvider);
  return state.todayBreakdown;
});

/// Provider per il progresso target giornaliero
final dailyProgressProvider = Provider<double>((ref) {
  final state = ref.watch(earningsProvider);
  return state.dailyTarget.progress;
});
