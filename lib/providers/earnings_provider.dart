import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../models/rider.dart';
import '../models/daily_target.dart';
import '../models/earning.dart';
import '../services/rush_hour_service.dart';
import '../services/orders_service.dart';
import '../services/earnings_service.dart';
import '../utils/logger.dart';
import '../widgets/earning_notification.dart';

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
    double base = 0, bonus = 0, tips = 0, rush = 0, hold = 0;

    for (var order in todayOrders.where((o) => o.status == OrderStatus.delivered)) {
      base += order.baseEarning;
      bonus += order.bonusEarning;
      tips += order.tipAmount;
      rush += order.rushBonus;
      hold += order.holdCost;
    }

    return {
      'base': base,
      'bonus': bonus,
      'tips': tips,
      'rush': rush,
      'hold': hold,
      'total': base + bonus + tips + rush + hold,
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
  StreamSubscription<List<Order>>? _ordersSub;

  EarningsNotifier() : super(EarningsState(
    dailyTarget: DailyTarget(date: DateTime.now()),
  )) {
    _subscribeToOrders();
  }

  /// Subscribe to real-time orders stream, fall back to demo data
  void _subscribeToOrders() {
    try {
      _ordersSub = OrdersService.subscribeToOrders().listen(
        (orders) {
          if (orders.isNotEmpty) {
            _applyOrders(orders);
          } else if (state.todayOrders.isEmpty) {
            _loadDemoData();
          }
        },
        onError: (e) {
          dlog('⚡ EarningsNotifier stream error: $e');
          if (state.todayOrders.isEmpty) _loadDemoData();
        },
      );
    } catch (_) {
      _loadDemoData();
    }
  }

  /// Reload: cancel stream and re-subscribe
  void reload() {
    _ordersSub?.cancel();
    _subscribeToOrders();
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    super.dispose();
  }

  /// Apply a list of orders to state (used after Supabase load)
  void _applyOrders(List<Order> orders) {
    var target = DailyTarget(date: DateTime.now());
    double km = 0;

    for (final order in orders) {
      if (order.status == OrderStatus.delivered) {
        target = target.addEarning(order.totalEarning);
        km += order.distanceKm;
      }
    }

    state = state.copyWith(
      todayOrders: orders,
      dailyTarget: target,
      totalKmToday: km,
    );
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

    // Ordine 2 - CONSEGNATO - pranzo rush hour + attesa
    _addDemoOrder(
      restaurantName: 'Rossopomodoro',
      customerAddress: 'Piazza Duomo 1',
      distanceKm: 2.3,
      tipAmount: 1.00,
      minutesAgo: 120,
      forceRush: true,
      holdMinutes: 12, // 12 min attesa = 7 min pagati
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

    // Ordine 4 - CONSEGNATO - lunga distanza + attesa
    _addDemoOrder(
      restaurantName: 'Sushi Zen',
      customerAddress: 'Corso Italia 88',
      distanceKm: 6.2, // lunga distanza: attiva bonus extra/km
      minutesAgo: 60,
      holdMinutes: 8, // 8 min attesa = 3 min pagati
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
    int holdMinutes = 0,
    OrderStatus status = OrderStatus.delivered,
  }) {
    final timestamp = DateTime.now().subtract(Duration(minutes: minutesAgo));
    final rushMultiplier = forceRush ? 2.0 : 1.0;
    const pricing = RiderPricing();
    final baseEarning = pricing.calculateBaseEarning(distanceKm);
    final holdCost = pricing.calculateHoldCost(holdMinutes);

    final order = Order(
      id: 'demo_${DateTime.now().millisecondsSinceEpoch}_$minutesAgo',
      restaurantName: restaurantName,
      customerAddress: customerAddress,
      distanceKm: distanceKm,
      baseEarning: baseEarning,
      tipAmount: tipAmount,
      rushMultiplier: rushMultiplier,
      holdCost: holdCost,
      holdMinutes: holdMinutes,
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

    // Persist to Supabase (skip demo orders)
    if (!order.id.startsWith('demo_') && !order.id.startsWith('order_')) {
      OrdersService.createOrder(acceptedOrder);
    }
  }

  /// Segna ordine come ritirato
  void pickupOrder() {
    if (state.activeOrder == null) return;
    final pickedUpOrder = state.activeOrder!.copyWithStatus(OrderStatus.pickedUp);
    state = state.copyWith(activeOrder: pickedUpOrder);

    // Persist status change (skip demo orders)
    if (!pickedUpOrder.id.startsWith('demo_') && !pickedUpOrder.id.startsWith('order_')) {
      OrdersService.updateOrderStatus(pickedUpOrder.id, OrderStatus.pickedUp);
    }
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

    // Persist order status + create earning record (skip demo orders)
    if (!completedOrder.id.startsWith('demo_') && !completedOrder.id.startsWith('order_')) {
      OrdersService.updateOrderStatus(completedOrder.id, OrderStatus.delivered);
      EarningsService.createEarning(Earning(
        id: '',
        type: EarningType.delivery,
        description: 'Consegna ${completedOrder.restaurantName}',
        amount: completedOrder.totalEarning,
        dateTime: DateTime.now(),
        status: EarningStatus.completed,
        orderId: completedOrder.id,
      ));
    }
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

    // Persist cancellation (skip demo orders)
    if (!cancelledOrder.id.startsWith('demo_') && !cancelledOrder.id.startsWith('order_')) {
      OrdersService.updateOrderStatus(cancelledOrder.id, OrderStatus.cancelled);
    }
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

/// Controller per le notifiche di incasso (singleton)
final earningNotificationControllerProvider = Provider<EarningNotificationController>((ref) {
  return EarningNotificationController();
});

/// Stato per tracciare guadagni dal Network
class NetworkEarningsState {
  final List<Earning> networkEarnings;
  final int notifiedCount;

  const NetworkEarningsState({
    this.networkEarnings = const [],
    this.notifiedCount = 0,
  });

  NetworkEarningsState copyWith({
    List<Earning>? networkEarnings,
    int? notifiedCount,
  }) {
    return NetworkEarningsState(
      networkEarnings: networkEarnings ?? this.networkEarnings,
      notifiedCount: notifiedCount ?? this.notifiedCount,
    );
  }
}

/// Notifier per i guadagni Network
class NetworkEarningsNotifier extends StateNotifier<NetworkEarningsState> {
  StreamSubscription<List<Earning>>? _earningsSub;

  NetworkEarningsNotifier() : super(const NetworkEarningsState()) {
    _subscribeToNetworkEarnings();
  }

  /// Subscribe to real-time earnings stream, filtering for network types
  void _subscribeToNetworkEarnings() {
    try {
      _earningsSub = EarningsService.subscribeToEarnings().listen(
        (allEarnings) {
          final networkEarnings = allEarnings
              .where((e) => e.type == EarningType.network && e.status == EarningStatus.completed)
              .toList();

          if (networkEarnings.isNotEmpty) {
            _applyNetworkEarnings(networkEarnings);
          } else if (state.networkEarnings.isEmpty) {
            _loadFallbackData();
          }
        },
        onError: (e) {
          dlog('⚡ NetworkEarningsNotifier stream error: $e');
          if (state.networkEarnings.isEmpty) _loadFallbackData();
        },
      );
    } catch (_) {
      _loadFallbackData();
    }
  }

  /// Apply incoming network earnings, preserving notifiedCount on first load
  void _applyNetworkEarnings(List<Earning> networkEarnings) {
    final isFirstLoad = state.networkEarnings.isEmpty && state.notifiedCount == 0;
    state = NetworkEarningsState(
      networkEarnings: networkEarnings,
      // First load: mark all as notified (no popup spam on app start)
      // Subsequent updates: keep existing notifiedCount so new ones trigger popup
      notifiedCount: isFirstLoad ? networkEarnings.length : state.notifiedCount,
    );
  }

  /// Fallback when Supabase is unavailable — empty state (no mock data)
  void _loadFallbackData() {
    state = const NetworkEarningsState(
      networkEarnings: [],
      notifiedCount: 0,
    );
  }

  @override
  void dispose() {
    _earningsSub?.cancel();
    super.dispose();
  }

  /// Simula arrivo di un nuovo guadagno Network (per demo/test)
  Earning? simulateNewNetworkEarning() {
    final names = ['Marco', 'Giulia', 'Andrea', 'Francesca', 'Luca', 'Sara'];
    final types = ['Commissione rete', 'Bonus referral', 'Bonus attivazione'];

    final random = DateTime.now().millisecondsSinceEpoch % names.length;
    final typeRandom = DateTime.now().millisecondsSinceEpoch % types.length;
    final amount = 2.0 + (DateTime.now().millisecondsSinceEpoch % 2000) / 100; // €2-22

    final newEarning = Earning(
      id: 'net_${DateTime.now().millisecondsSinceEpoch}',
      type: EarningType.network,
      description: '${types[typeRandom]} - ${names[random]}',
      amount: amount,
      dateTime: DateTime.now(),
      status: EarningStatus.completed,
    );

    state = state.copyWith(
      networkEarnings: [...state.networkEarnings, newEarning],
    );

    // Persist to Supabase (only real earnings, skip net_ demo IDs)
    if (!newEarning.id.startsWith('net_')) {
      EarningsService.createEarning(newEarning);
    }

    return newEarning;
  }

  /// Segna come notificato fino all'ultimo guadagno
  void markAsNotified() {
    state = state.copyWith(notifiedCount: state.networkEarnings.length);
  }

  /// Controlla se ci sono nuovi guadagni non notificati
  List<Earning> getUnnotifiedEarnings() {
    if (state.networkEarnings.length <= state.notifiedCount) {
      return [];
    }
    return state.networkEarnings.sublist(state.notifiedCount);
  }
}

/// Provider per i guadagni Network
final networkEarningsProvider = StateNotifierProvider<NetworkEarningsNotifier, NetworkEarningsState>(
  (ref) => NetworkEarningsNotifier(),
);
