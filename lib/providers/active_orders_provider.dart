import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../models/earning.dart';
import '../services/orders_service.dart';
import '../services/earnings_service.dart';
import '../services/rush_hour_service.dart';

/// Stati di un ordine attivo
enum OrderPhase {
  toPickup,    // In viaggio verso punto ritiro
  atPickup,    // Arrivato al punto ritiro
  toCustomer,  // In viaggio verso cliente
  atCustomer,  // Arrivato dal cliente
  completed,   // Consegnato
}

/// Ordine attivo con stato
class ActiveOrder {
  final String id;
  final String dealerName;
  final String dealerAddress;
  final String customerAddress;
  final double distanceKm;
  final String? orderNotes;
  final DateTime acceptedAt;
  final bool isDemo;
  final bool isPriorityAssigned;
  final DateTime? priorityExpiresAt;
  final int dispatchAttempt;
  OrderPhase phase;

  ActiveOrder({
    required this.id,
    required this.dealerName,
    required this.dealerAddress,
    required this.customerAddress,
    required this.distanceKm,
    this.orderNotes,
    required this.acceptedAt,
    this.isDemo = false,
    this.isPriorityAssigned = false,
    this.priorityExpiresAt,
    this.dispatchAttempt = 0,
    this.phase = OrderPhase.toPickup,
  });

  /// Create from DB Order
  factory ActiveOrder.fromOrder(Order order) {
    OrderPhase phase;
    switch (order.status) {
      case OrderStatus.pending:
        phase = OrderPhase.toPickup;
        break;
      case OrderStatus.accepted:
        phase = OrderPhase.toPickup;
        break;
      case OrderStatus.pickedUp:
        phase = OrderPhase.toCustomer;
        break;
      default:
        phase = OrderPhase.completed;
    }

    // Check if this order is priority-assigned to the current rider
    final hasPriority = order.assignedRiderId != null &&
        order.priorityExpiresAt != null &&
        order.priorityExpiresAt!.isAfter(DateTime.now()) &&
        order.status == OrderStatus.pending;

    return ActiveOrder(
      id: order.id,
      dealerName: order.restaurantName,
      dealerAddress: order.restaurantAddress,
      customerAddress: order.customerAddress,
      distanceKm: order.distanceKm,
      orderNotes: null,
      acceptedAt: order.acceptedAt ?? order.createdAt,
      isPriorityAssigned: hasPriority,
      priorityExpiresAt: order.priorityExpiresAt,
      dispatchAttempt: order.dispatchAttempts,
      phase: phase,
    );
  }

  /// Guadagno base
  double get baseEarning => distanceKm * 1.50;

  /// Guadagno con rush hour
  double get totalEarning => baseEarning * RushHourService.getCurrentMultiplier();

  /// Label stato
  String get phaseLabel {
    switch (phase) {
      case OrderPhase.toPickup:
        return 'DA RITIRARE';
      case OrderPhase.atPickup:
        return 'IN RITIRO';
      case OrderPhase.toCustomer:
        return 'IN CONSEGNA';
      case OrderPhase.atCustomer:
        return 'AL CLIENTE';
      case OrderPhase.completed:
        return 'COMPLETATO';
    }
  }

  /// Label pulsante azione
  String get actionLabel {
    switch (phase) {
      case OrderPhase.toPickup:
        return 'ARRIVO AL RITIRO';
      case OrderPhase.atPickup:
        return 'RITIRATO';
      case OrderPhase.toCustomer:
        return 'ARRIVO CONSEGNA';
      case OrderPhase.atCustomer:
        return 'CONSEGNATO';
      case OrderPhase.completed:
        return 'COMPLETATO';
    }
  }

  /// Copia con nuovo stato
  ActiveOrder copyWith({
    OrderPhase? phase,
    bool? isPriorityAssigned,
  }) {
    return ActiveOrder(
      id: id,
      dealerName: dealerName,
      dealerAddress: dealerAddress,
      customerAddress: customerAddress,
      distanceKm: distanceKm,
      orderNotes: orderNotes,
      acceptedAt: acceptedAt,
      isDemo: isDemo,
      isPriorityAssigned: isPriorityAssigned ?? this.isPriorityAssigned,
      priorityExpiresAt: priorityExpiresAt,
      dispatchAttempt: dispatchAttempt,
      phase: phase ?? this.phase,
    );
  }

  /// Genera ordine random (fallback demo)
  static ActiveOrder generate() {
    final random = Random();

    const dealers = [
      ('Pizzeria Da Mario', 'Via Torino 25'),
      ('Sushi Zen', 'Corso Italia 12'),
      ('Farmacia Centrale', 'Via Dante 8'),
      ('Burger King', 'Piazza Duomo 3'),
      ("McDonald's", 'Via Montenapoleone 15'),
      ('Poke House', 'Corso Buenos Aires 88'),
      ('Supermercato Esselunga', 'Via Brera 22'),
      ('La Piadineria', 'Via Paolo Sarpi 44'),
      ('Libreria Feltrinelli', 'Viale Papiniano 10'),
      ('Fiorista Rosa', 'Corso Sempione 5'),
    ];

    const customerAddresses = [
      'Via Roma 15',
      'Corso Italia 88',
      'Via Torino 12',
      'Via Dante 23',
      'Corso Buenos Aires 45',
      'Via Montenapoleone 8',
      'Piazza Duomo 1',
      'Via Brera 30',
      'Corso Sempione 76',
      'Via Paolo Sarpi 55',
    ];

    const notes = [
      null,
      'Citofono rotto, chiamare',
      'Consegnare al portiere',
      'Piano 3, scala B',
      'Suonare 2 volte',
      null,
      'Lasciare fuori dalla porta',
      null,
    ];

    final dealer = dealers[random.nextInt(dealers.length)];
    final distance = 0.8 + random.nextDouble() * 3.5;

    return ActiveOrder(
      id: 'demo_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000)}',
      dealerName: dealer.$1,
      dealerAddress: dealer.$2,
      customerAddress: customerAddresses[random.nextInt(customerAddresses.length)],
      distanceKm: double.parse(distance.toStringAsFixed(1)),
      orderNotes: notes[random.nextInt(notes.length)],
      acceptedAt: DateTime.now(),
      isDemo: true,
    );
  }
}

/// State per ordini attivi
class ActiveOrdersState {
  final List<ActiveOrder> orders;
  final List<ActiveOrder> availableOrders;

  const ActiveOrdersState({
    this.orders = const [],
    this.availableOrders = const [],
  });

  /// Guadagno totale ordini attivi
  double get totalEarning => orders
      .where((o) => o.phase != OrderPhase.completed)
      .fold(0.0, (sum, o) => sum + o.totalEarning);

  /// Numero ordini attivi (non completati)
  int get activeCount => orders.where((o) => o.phase != OrderPhase.completed).length;

  ActiveOrdersState copyWith({
    List<ActiveOrder>? orders,
    List<ActiveOrder>? availableOrders,
  }) {
    return ActiveOrdersState(
      orders: orders ?? this.orders,
      availableOrders: availableOrders ?? this.availableOrders,
    );
  }
}

/// Notifier per gestire ordini attivi — wired to Supabase real-time
class ActiveOrdersNotifier extends StateNotifier<ActiveOrdersState> {
  StreamSubscription<List<Order>>? _ordersSub;

  ActiveOrdersNotifier() : super(const ActiveOrdersState()) {
    _subscribeToOrders();
  }

  void _subscribeToOrders() {
    _ordersSub = OrdersService.subscribeToOrders().listen(
      (orders) {
        // Pending orders → available (rider can accept)
        final pending = orders
            .where((o) => o.status == OrderStatus.pending)
            .map((o) => ActiveOrder.fromOrder(o))
            .toList();

        // Accepted/picked up → active orders (rider is working on)
        final active = orders
            .where((o) =>
                o.status == OrderStatus.accepted ||
                o.status == OrderStatus.pickedUp)
            .map((o) {
              // Preserve local phase if we already have this order
              final existing = state.orders.where((a) => a.id == o.id);
              if (existing.isNotEmpty) return existing.first;
              return ActiveOrder.fromOrder(o);
            })
            .toList();

        state = state.copyWith(
          orders: active,
          availableOrders: pending,
        );

        // If no data at all, add demo fallback (debug only)
        if (kDebugMode && orders.isEmpty && state.orders.isEmpty && state.availableOrders.isEmpty) {
          _loadDemoOrders();
        }
      },
      onError: (_) {
        if (kDebugMode && state.availableOrders.isEmpty) _loadDemoOrders();
      },
    );
  }

  void _loadDemoOrders() {
    if (!kDebugMode) return;
    state = state.copyWith(
      availableOrders: List.generate(4, (_) => ActiveOrder.generate()),
    );
  }

  /// Reload: cancel stream and re-subscribe
  void reload() {
    _ordersSub?.cancel();
    _subscribeToOrders();
  }

  /// Rifiuta un ordine assegnato via Smart Dispatch
  void rejectAssignedOrder(String orderId) {
    state = state.copyWith(
      availableOrders: state.availableOrders.where((o) => o.id != orderId).toList(),
    );
    OrdersService.rejectAssignedOrder(orderId);
  }

  /// Accetta un ordine disponibile
  void acceptOrder(ActiveOrder order) {
    state = state.copyWith(
      orders: [...state.orders, order.copyWith(phase: OrderPhase.toPickup)],
      availableOrders: state.availableOrders.where((o) => o.id != order.id).toList(),
    );
    // Persist to Supabase (skip demo orders)
    if (!order.isDemo) {
      OrdersService.updateOrderStatus(order.id, OrderStatus.accepted);
    }
  }

  /// Avanza fase di un ordine (persists DB-relevant transitions)
  void advanceOrder(String orderId) {
    state = state.copyWith(
      orders: state.orders.map((order) {
        if (order.id == orderId) {
          OrderPhase nextPhase;
          switch (order.phase) {
            case OrderPhase.toPickup:
              nextPhase = OrderPhase.atPickup;
              break;
            case OrderPhase.atPickup:
              nextPhase = OrderPhase.toCustomer;
              if (!order.isDemo) {
                OrdersService.updateOrderStatus(orderId, OrderStatus.pickedUp);
              }
              break;
            case OrderPhase.toCustomer:
              nextPhase = OrderPhase.atCustomer;
              break;
            case OrderPhase.atCustomer:
              nextPhase = OrderPhase.completed;
              if (!order.isDemo) {
                OrdersService.updateOrderStatus(orderId, OrderStatus.delivered);
                // Auto-create transaction for the completed delivery
                EarningsService.createEarning(Earning(
                  id: '',
                  type: EarningType.delivery,
                  description: 'Consegna ${order.dealerName} → ${order.customerAddress}',
                  amount: order.totalEarning,
                  dateTime: DateTime.now(),
                  status: EarningStatus.completed,
                  orderId: orderId,
                ));
              }
              break;
            case OrderPhase.completed:
              nextPhase = OrderPhase.completed;
              break;
          }
          return order.copyWith(phase: nextPhase);
        }
        return order;
      }).toList(),
    );
  }

  /// Rimuovi ordine completato dalla lista
  void removeCompletedOrder(String orderId) {
    state = state.copyWith(
      orders: state.orders.where((o) => o.id != orderId).toList(),
    );
  }

  /// Annulla ordine
  void cancelOrder(String orderId) {
    final order = state.orders.where((o) => o.id == orderId);
    final isDemo = order.isNotEmpty && order.first.isDemo;
    state = state.copyWith(
      orders: state.orders.where((o) => o.id != orderId).toList(),
      availableOrders: order.isNotEmpty
          ? [...state.availableOrders, order.first.copyWith(phase: OrderPhase.toPickup)]
          : state.availableOrders,
    );
    // Persist cancellation (skip demo orders)
    if (!isDemo) {
      OrdersService.updateOrderStatus(orderId, OrderStatus.cancelled);
    }
  }

  /// Aggiorna lista ordini disponibili (demo fallback, debug only)
  void refreshAvailableOrders() {
    if (!kDebugMode) return;
    state = state.copyWith(
      availableOrders: List.generate(3 + Random().nextInt(3), (_) => ActiveOrder.generate()),
    );
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    super.dispose();
  }
}

/// Provider per ordini attivi
final activeOrdersProvider = StateNotifierProvider<ActiveOrdersNotifier, ActiveOrdersState>(
  (ref) => ActiveOrdersNotifier(),
);
