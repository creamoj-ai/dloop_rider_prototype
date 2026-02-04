import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  OrderPhase phase;

  ActiveOrder({
    required this.id,
    required this.dealerName,
    required this.dealerAddress,
    required this.customerAddress,
    required this.distanceKm,
    this.orderNotes,
    required this.acceptedAt,
    this.phase = OrderPhase.toPickup,
  });

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
  ActiveOrder copyWith({OrderPhase? phase}) {
    return ActiveOrder(
      id: id,
      dealerName: dealerName,
      dealerAddress: dealerAddress,
      customerAddress: customerAddress,
      distanceKm: distanceKm,
      orderNotes: orderNotes,
      acceptedAt: acceptedAt,
      phase: phase ?? this.phase,
    );
  }

  /// Genera ordine random
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
      id: 'order_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000)}',
      dealerName: dealer.$1,
      dealerAddress: dealer.$2,
      customerAddress: customerAddresses[random.nextInt(customerAddresses.length)],
      distanceKm: double.parse(distance.toStringAsFixed(1)),
      orderNotes: notes[random.nextInt(notes.length)],
      acceptedAt: DateTime.now(),
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

/// Notifier per gestire ordini attivi
class ActiveOrdersNotifier extends StateNotifier<ActiveOrdersState> {
  ActiveOrdersNotifier() : super(ActiveOrdersState(
    availableOrders: List.generate(4, (_) => ActiveOrder.generate()),
  ));

  /// Accetta un ordine disponibile
  void acceptOrder(ActiveOrder order) {
    state = state.copyWith(
      orders: [...state.orders, order.copyWith(phase: OrderPhase.toPickup)],
      availableOrders: state.availableOrders.where((o) => o.id != order.id).toList(),
    );
    // Rigenera ordini disponibili se pochi
    if (state.availableOrders.length < 2) {
      refreshAvailableOrders();
    }
  }

  /// Avanza fase di un ordine
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
              break;
            case OrderPhase.toCustomer:
              nextPhase = OrderPhase.atCustomer;
              break;
            case OrderPhase.atCustomer:
              nextPhase = OrderPhase.completed;
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
    final order = state.orders.firstWhere((o) => o.id == orderId);
    state = state.copyWith(
      orders: state.orders.where((o) => o.id != orderId).toList(),
      // Rimetti l'ordine tra quelli disponibili
      availableOrders: [...state.availableOrders, order.copyWith(phase: OrderPhase.toPickup)],
    );
  }

  /// Aggiorna lista ordini disponibili
  void refreshAvailableOrders() {
    state = state.copyWith(
      availableOrders: List.generate(3 + Random().nextInt(3), (_) => ActiveOrder.generate()),
    );
  }
}

/// Provider per ordini attivi
final activeOrdersProvider = StateNotifierProvider<ActiveOrdersNotifier, ActiveOrdersState>(
  (ref) => ActiveOrdersNotifier(),
);
