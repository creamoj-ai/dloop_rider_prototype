import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/order.dart';
import 'package:dloop_rider_prototype/providers/active_orders_provider.dart';

void main() {
  group('ActiveOrder priority fields', () {
    test('default isPriorityAssigned is false', () {
      final order = ActiveOrder(
        id: 'p1',
        dealerName: 'Test',
        dealerAddress: 'A',
        customerAddress: 'B',
        distanceKm: 2.0,
        acceptedAt: DateTime.now(),
      );

      expect(order.isPriorityAssigned, false);
      expect(order.priorityExpiresAt, isNull);
      expect(order.dispatchAttempt, 0);
    });

    test('priority order has correct fields', () {
      final expiresAt = DateTime.now().add(const Duration(seconds: 60));
      final order = ActiveOrder(
        id: 'p2',
        dealerName: 'Pizza',
        dealerAddress: 'Via Roma',
        customerAddress: 'Via Dante',
        distanceKm: 1.5,
        acceptedAt: DateTime.now(),
        isPriorityAssigned: true,
        priorityExpiresAt: expiresAt,
        dispatchAttempt: 2,
      );

      expect(order.isPriorityAssigned, true);
      expect(order.priorityExpiresAt, expiresAt);
      expect(order.dispatchAttempt, 2);
    });

    test('copyWith can toggle isPriorityAssigned', () {
      final order = ActiveOrder(
        id: 'p3',
        dealerName: 'T',
        dealerAddress: 'A',
        customerAddress: 'B',
        distanceKm: 1.0,
        acceptedAt: DateTime.now(),
        isPriorityAssigned: true,
      );

      final updated = order.copyWith(isPriorityAssigned: false);
      expect(updated.isPriorityAssigned, false);
      expect(updated.id, 'p3');
    });
  });

  group('ActiveOrder.fromOrder with priority', () {
    test('detects priority assignment (pending + assigned + future expiry)', () {
      final expiresAt = DateTime.now().add(const Duration(seconds: 45));
      final dbOrder = Order(
        id: 'db-priority',
        restaurantName: 'Sushi Zen',
        restaurantAddress: 'Via C',
        customerAddress: 'Via D',
        distanceKm: 2.0,
        baseEarning: 3.0,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        assignedRiderId: 'rider-abc',
        priorityExpiresAt: expiresAt,
        dispatchAttempts: 1,
      );

      final active = ActiveOrder.fromOrder(dbOrder);
      expect(active.isPriorityAssigned, true);
      expect(active.priorityExpiresAt, expiresAt);
      expect(active.dispatchAttempt, 1);
    });

    test('no priority when expiry is in the past', () {
      final expiredAt = DateTime.now().subtract(const Duration(seconds: 10));
      final dbOrder = Order(
        id: 'db-expired',
        restaurantName: 'T',
        customerAddress: 'A',
        distanceKm: 1.0,
        baseEarning: 3.0,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        assignedRiderId: 'rider-abc',
        priorityExpiresAt: expiredAt,
      );

      final active = ActiveOrder.fromOrder(dbOrder);
      expect(active.isPriorityAssigned, false);
    });

    test('no priority when status is not pending', () {
      final expiresAt = DateTime.now().add(const Duration(seconds: 45));
      final dbOrder = Order(
        id: 'db-accepted',
        restaurantName: 'T',
        customerAddress: 'A',
        distanceKm: 1.0,
        baseEarning: 3.0,
        status: OrderStatus.accepted,
        createdAt: DateTime.now(),
        assignedRiderId: 'rider-abc',
        priorityExpiresAt: expiresAt,
      );

      final active = ActiveOrder.fromOrder(dbOrder);
      expect(active.isPriorityAssigned, false);
    });

    test('no priority when assignedRiderId is null', () {
      final dbOrder = Order(
        id: 'db-unassigned',
        restaurantName: 'T',
        customerAddress: 'A',
        distanceKm: 1.0,
        baseEarning: 3.0,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        priorityExpiresAt: DateTime.now().add(const Duration(seconds: 60)),
      );

      final active = ActiveOrder.fromOrder(dbOrder);
      expect(active.isPriorityAssigned, false);
    });
  });

  group('ActiveOrdersState with priority orders', () {
    test('availableOrders can contain both priority and regular orders', () {
      final priorityOrder = ActiveOrder(
        id: 'priority-1',
        dealerName: 'Pizza',
        dealerAddress: 'Via A',
        customerAddress: 'Via B',
        distanceKm: 1.0,
        acceptedAt: DateTime.now(),
        isPriorityAssigned: true,
        priorityExpiresAt: DateTime.now().add(const Duration(seconds: 60)),
      );

      final regularOrder = ActiveOrder(
        id: 'regular-1',
        dealerName: 'Sushi',
        dealerAddress: 'Via C',
        customerAddress: 'Via D',
        distanceKm: 2.0,
        acceptedAt: DateTime.now(),
        isPriorityAssigned: false,
      );

      final state = ActiveOrdersState(
        availableOrders: [priorityOrder, regularOrder],
      );

      final priorities = state.availableOrders.where((o) => o.isPriorityAssigned).toList();
      final regulars = state.availableOrders.where((o) => !o.isPriorityAssigned).toList();

      expect(priorities.length, 1);
      expect(regulars.length, 1);
      expect(priorities.first.id, 'priority-1');
      expect(regulars.first.id, 'regular-1');
    });
  });

  group('Order dispatch fields', () {
    test('fromJson parses dispatch_status and dispatch_attempts', () {
      final json = {
        'id': 'order-dispatch',
        'restaurant_name': 'Test',
        'customer_address': 'Addr',
        'distance_km': 2.0,
        'base_earning': 3.0,
        'status': 'pending',
        'created_at': '2026-02-13T12:00:00Z',
        'dispatch_status': 'assigned',
        'dispatch_attempts': 2,
        'assigned_rider_id': 'rider-xyz',
        'priority_expires_at': '2026-02-13T12:01:00Z',
      };

      final order = Order.fromJson(json);

      expect(order.dispatchStatus, 'assigned');
      expect(order.dispatchAttempts, 2);
      expect(order.assignedRiderId, 'rider-xyz');
      expect(order.priorityExpiresAt, isNotNull);
    });

    test('toJson includes dispatch fields', () {
      final order = Order(
        id: 'json-dispatch',
        restaurantName: 'Test',
        customerAddress: 'Addr',
        distanceKm: 1.0,
        baseEarning: 3.0,
        createdAt: DateTime(2026, 2, 13),
        dispatchStatus: 'broadcast',
        dispatchAttempts: 3,
      );

      final json = order.toJson();
      expect(json['dispatch_status'], 'broadcast');
      expect(json['dispatch_attempts'], 3);
    });
  });
}
