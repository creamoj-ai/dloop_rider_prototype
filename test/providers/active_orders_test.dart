import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/order.dart';
import 'package:dloop_rider_prototype/providers/active_orders_provider.dart';

void main() {
  group('OrderPhase enum', () {
    test('has all expected values', () {
      expect(OrderPhase.values, [
        OrderPhase.toPickup,
        OrderPhase.atPickup,
        OrderPhase.toCustomer,
        OrderPhase.atCustomer,
        OrderPhase.completed,
      ]);
    });
  });

  group('ActiveOrder', () {
    test('generate() creates a demo order with isDemo=true', () {
      final order = ActiveOrder.generate();

      expect(order.isDemo, true);
      expect(order.id, startsWith('demo_'));
      expect(order.dealerName, isNotEmpty);
      expect(order.dealerAddress, isNotEmpty);
      expect(order.customerAddress, isNotEmpty);
      expect(order.distanceKm, greaterThan(0));
      expect(order.phase, OrderPhase.toPickup);
    });

    test('generate() produces different orders', () {
      // Small delay to ensure different timestamps
      final order1 = ActiveOrder.generate();
      final order2 = ActiveOrder.generate();

      // IDs are based on millisecond timestamp + random, should differ
      expect(order1.id, isNot(equals(order2.id)));
    });

    test('copyWith changes phase', () {
      final order = ActiveOrder(
        id: 'test-1',
        dealerName: 'Pizza',
        dealerAddress: 'Via Roma 1',
        customerAddress: 'Via Dante 5',
        distanceKm: 2.0,
        acceptedAt: DateTime(2026, 2, 10, 12),
        phase: OrderPhase.toPickup,
      );

      final advanced = order.copyWith(phase: OrderPhase.atPickup);

      expect(advanced.phase, OrderPhase.atPickup);
      expect(advanced.id, order.id);
      expect(advanced.dealerName, order.dealerName);
      expect(advanced.distanceKm, order.distanceKm);
      expect(advanced.isDemo, order.isDemo);
    });

    test('copyWith without parameters returns same phase', () {
      final order = ActiveOrder(
        id: 'test-2',
        dealerName: 'Sushi',
        dealerAddress: 'Via A',
        customerAddress: 'Via B',
        distanceKm: 3.0,
        acceptedAt: DateTime.now(),
        phase: OrderPhase.toCustomer,
      );

      final copy = order.copyWith();
      expect(copy.phase, OrderPhase.toCustomer);
    });

    test('phase progression: toPickup -> atPickup -> toCustomer -> atCustomer -> completed', () {
      var order = ActiveOrder(
        id: 'phase-test',
        dealerName: 'Test',
        dealerAddress: 'A',
        customerAddress: 'B',
        distanceKm: 1.0,
        acceptedAt: DateTime.now(),
        phase: OrderPhase.toPickup,
      );

      expect(order.phase, OrderPhase.toPickup);

      order = order.copyWith(phase: OrderPhase.atPickup);
      expect(order.phase, OrderPhase.atPickup);

      order = order.copyWith(phase: OrderPhase.toCustomer);
      expect(order.phase, OrderPhase.toCustomer);

      order = order.copyWith(phase: OrderPhase.atCustomer);
      expect(order.phase, OrderPhase.atCustomer);

      order = order.copyWith(phase: OrderPhase.completed);
      expect(order.phase, OrderPhase.completed);
    });

    test('demo orders have ID prefix demo_', () {
      final order = ActiveOrder.generate();
      expect(order.id, startsWith('demo_'));
    });

    test('baseEarning = distanceKm * 1.50', () {
      final order = ActiveOrder(
        id: 'base-test',
        dealerName: 'T',
        dealerAddress: 'A',
        customerAddress: 'B',
        distanceKm: 4.0,
        acceptedAt: DateTime.now(),
      );

      expect(order.baseEarning, 6.0); // 4.0 * 1.50
    });

    group('phaseLabel', () {
      test('returns correct Italian labels', () {
        final labels = {
          OrderPhase.toPickup: 'DA RITIRARE',
          OrderPhase.atPickup: 'IN RITIRO',
          OrderPhase.toCustomer: 'IN CONSEGNA',
          OrderPhase.atCustomer: 'AL CLIENTE',
          OrderPhase.completed: 'COMPLETATO',
        };

        for (final entry in labels.entries) {
          final order = ActiveOrder(
            id: 'label-${entry.key.name}',
            dealerName: 'T',
            dealerAddress: 'A',
            customerAddress: 'B',
            distanceKm: 1.0,
            acceptedAt: DateTime.now(),
            phase: entry.key,
          );
          expect(order.phaseLabel, entry.value);
        }
      });
    });

    group('actionLabel', () {
      test('returns correct Italian action labels', () {
        final actions = {
          OrderPhase.toPickup: 'ARRIVO AL RITIRO',
          OrderPhase.atPickup: 'RITIRATO',
          OrderPhase.toCustomer: 'ARRIVO CONSEGNA',
          OrderPhase.atCustomer: 'CONSEGNATO',
          OrderPhase.completed: 'COMPLETATO',
        };

        for (final entry in actions.entries) {
          final order = ActiveOrder(
            id: 'action-${entry.key.name}',
            dealerName: 'T',
            dealerAddress: 'A',
            customerAddress: 'B',
            distanceKm: 1.0,
            acceptedAt: DateTime.now(),
            phase: entry.key,
          );
          expect(order.actionLabel, entry.value);
        }
      });
    });

    group('fromOrder', () {
      test('maps pending Order to toPickup phase', () {
        final dbOrder = Order(
          id: 'db-1',
          restaurantName: 'Pizza',
          restaurantAddress: 'Via A',
          customerAddress: 'Via B',
          distanceKm: 2.0,
          baseEarning: 3.0,
          status: OrderStatus.pending,
          createdAt: DateTime(2026, 2, 10, 12),
        );

        final active = ActiveOrder.fromOrder(dbOrder);
        expect(active.phase, OrderPhase.toPickup);
        expect(active.dealerName, 'Pizza');
        expect(active.dealerAddress, 'Via A');
        expect(active.customerAddress, 'Via B');
      });

      test('maps accepted Order to toPickup phase', () {
        final dbOrder = Order(
          id: 'db-2',
          restaurantName: 'Sushi',
          restaurantAddress: 'Via C',
          customerAddress: 'Via D',
          distanceKm: 3.0,
          baseEarning: 4.5,
          status: OrderStatus.accepted,
          createdAt: DateTime(2026, 2, 10, 12),
          acceptedAt: DateTime(2026, 2, 10, 12, 5),
        );

        final active = ActiveOrder.fromOrder(dbOrder);
        expect(active.phase, OrderPhase.toPickup);
        expect(active.acceptedAt, DateTime(2026, 2, 10, 12, 5));
      });

      test('maps pickedUp Order to toCustomer phase', () {
        final dbOrder = Order(
          id: 'db-3',
          restaurantName: 'Burger',
          restaurantAddress: 'Via E',
          customerAddress: 'Via F',
          distanceKm: 1.5,
          baseEarning: 3.0,
          status: OrderStatus.pickedUp,
          createdAt: DateTime(2026, 2, 10, 12),
          acceptedAt: DateTime(2026, 2, 10, 12, 5),
          pickedUpAt: DateTime(2026, 2, 10, 12, 10),
        );

        final active = ActiveOrder.fromOrder(dbOrder);
        expect(active.phase, OrderPhase.toCustomer);
      });

      test('maps delivered/cancelled to completed phase', () {
        final delivered = Order(
          id: 'db-4',
          restaurantName: 'T',
          customerAddress: 'A',
          distanceKm: 1.0,
          baseEarning: 3.0,
          status: OrderStatus.delivered,
          createdAt: DateTime(2026, 2, 10),
        );

        expect(ActiveOrder.fromOrder(delivered).phase, OrderPhase.completed);

        final cancelled = Order(
          id: 'db-5',
          restaurantName: 'T',
          customerAddress: 'A',
          distanceKm: 1.0,
          baseEarning: 3.0,
          status: OrderStatus.cancelled,
          createdAt: DateTime(2026, 2, 10),
        );

        expect(ActiveOrder.fromOrder(cancelled).phase, OrderPhase.completed);
      });
    });
  });

  group('ActiveOrdersState', () {
    test('default state has empty lists', () {
      const state = ActiveOrdersState();
      expect(state.orders, isEmpty);
      expect(state.availableOrders, isEmpty);
      expect(state.activeCount, 0);
      expect(state.totalEarning, 0);
    });

    test('activeCount excludes completed orders', () {
      final state = ActiveOrdersState(
        orders: [
          ActiveOrder(
            id: '1',
            dealerName: 'T',
            dealerAddress: 'A',
            customerAddress: 'B',
            distanceKm: 2.0,
            acceptedAt: DateTime.now(),
            phase: OrderPhase.toPickup,
          ),
          ActiveOrder(
            id: '2',
            dealerName: 'T',
            dealerAddress: 'A',
            customerAddress: 'B',
            distanceKm: 3.0,
            acceptedAt: DateTime.now(),
            phase: OrderPhase.completed,
          ),
          ActiveOrder(
            id: '3',
            dealerName: 'T',
            dealerAddress: 'A',
            customerAddress: 'B',
            distanceKm: 1.5,
            acceptedAt: DateTime.now(),
            phase: OrderPhase.toCustomer,
          ),
        ],
      );

      expect(state.activeCount, 2);
    });

    test('copyWith overwrites specified fields', () {
      const state = ActiveOrdersState();
      final available = [ActiveOrder.generate(), ActiveOrder.generate()];

      final updated = state.copyWith(availableOrders: available);

      expect(updated.availableOrders.length, 2);
      expect(updated.orders, isEmpty);
    });
  });
}
