import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/order.dart';
import 'package:dloop_rider_prototype/models/rider.dart';

void main() {
  group('OrderStatus enum', () {
    test('has all expected values', () {
      expect(OrderStatus.values, [
        OrderStatus.pending,
        OrderStatus.accepted,
        OrderStatus.pickedUp,
        OrderStatus.delivered,
        OrderStatus.cancelled,
      ]);
    });
  });

  group('Order.fromJson', () {
    test('with complete data returns valid Order', () {
      final json = {
        'id': 'order-123',
        'restaurant_name': 'Pizza Napoli',
        'restaurant_address': 'Via Roma 1',
        'customer_name': 'Mario Rossi',
        'customer_address': 'Via Dante 5',
        'distance_km': 3.5,
        'base_earning': 5.25,
        'bonus_earning': 1.0,
        'tip_amount': 2.0,
        'rush_multiplier': 1.5,
        'hold_cost': 0.75,
        'hold_minutes': 10,
        'min_guarantee': 3.0,
        'status': 'accepted',
        'created_at': '2026-02-10T12:00:00Z',
        'accepted_at': '2026-02-10T12:05:00Z',
        'picked_up_at': null,
        'delivered_at': null,
      };

      final order = Order.fromJson(json);

      expect(order.id, 'order-123');
      expect(order.restaurantName, 'Pizza Napoli');
      expect(order.restaurantAddress, 'Via Roma 1');
      expect(order.customerName, 'Mario Rossi');
      expect(order.customerAddress, 'Via Dante 5');
      expect(order.distanceKm, 3.5);
      expect(order.baseEarning, 5.25);
      expect(order.bonusEarning, 1.0);
      expect(order.tipAmount, 2.0);
      expect(order.rushMultiplier, 1.5);
      expect(order.holdCost, 0.75);
      expect(order.holdMinutes, 10);
      expect(order.minGuarantee, 3.0);
      expect(order.status, OrderStatus.accepted);
      expect(order.acceptedAt, isNotNull);
      expect(order.pickedUpAt, isNull);
      expect(order.deliveredAt, isNull);
    });

    test('with missing/null fields uses defaults', () {
      final json = <String, dynamic>{
        'id': null,
        'created_at': '2026-02-10T12:00:00Z',
      };

      final order = Order.fromJson(json);

      expect(order.id, '');
      expect(order.restaurantName, 'Ordine');
      expect(order.restaurantAddress, '');
      expect(order.customerName, '');
      expect(order.customerAddress, '');
      expect(order.distanceKm, 0.0);
      expect(order.baseEarning, 0.0);
      expect(order.bonusEarning, 0.0);
      expect(order.tipAmount, 0.0);
      expect(order.rushMultiplier, 1.0);
      expect(order.holdCost, 0.0);
      expect(order.holdMinutes, 0);
      expect(order.minGuarantee, 3.0);
      expect(order.status, OrderStatus.pending);
    });

    test('with decimal-as-string parses correctly', () {
      final json = {
        'id': 'order-456',
        'restaurant_name': 'Sushi Bar',
        'customer_address': 'Via Test 1',
        'distance_km': '4.50',
        'base_earning': '6.75',
        'bonus_earning': '1.25',
        'tip_amount': '3.00',
        'rush_multiplier': '2.0',
        'hold_cost': '0.30',
        'hold_minutes': '8',
        'min_guarantee': '3.00',
        'status': 'pending',
        'created_at': '2026-02-10T12:00:00Z',
      };

      final order = Order.fromJson(json);

      expect(order.distanceKm, 4.5);
      expect(order.baseEarning, 6.75);
      expect(order.bonusEarning, 1.25);
      expect(order.tipAmount, 3.0);
      expect(order.rushMultiplier, 2.0);
      expect(order.holdCost, 0.3);
      expect(order.holdMinutes, 8);
    });

    test('maps DB status strings correctly', () {
      // DB uses 'picked_up', Dart enum uses 'pickedUp'
      final json = {
        'id': 'o1',
        'restaurant_name': 'Test',
        'customer_address': 'Addr',
        'distance_km': 1.0,
        'base_earning': 3.0,
        'status': 'picked_up',
        'created_at': '2026-02-10T12:00:00Z',
      };

      final order = Order.fromJson(json);
      expect(order.status, OrderStatus.pickedUp);
    });

    test('with unknown status falls back to pending', () {
      final json = {
        'id': 'o2',
        'restaurant_name': 'Test',
        'customer_address': 'Addr',
        'distance_km': 1.0,
        'base_earning': 3.0,
        'status': 'unknown_status',
        'created_at': '2026-02-10T12:00:00Z',
      };

      final order = Order.fromJson(json);
      expect(order.status, OrderStatus.pending);
    });

    test('uses pickup_address and delivery_address DB column aliases', () {
      final json = {
        'id': 'o3',
        'pickup_address': 'Via Pickup 10, Napoli',
        'delivery_address': 'Via Delivery 20',
        'distance_km': 2.0,
        'base_earning': 3.0,
        'status': 'pending',
        'created_at': '2026-02-10T12:00:00Z',
      };

      final order = Order.fromJson(json);
      // restaurant_name falls back to first part of pickup_address
      expect(order.restaurantName, 'Via Pickup 10');
      expect(order.restaurantAddress, 'Via Pickup 10, Napoli');
      expect(order.customerAddress, 'Via Delivery 20');
    });

    test('uses base_earnings DB column alias', () {
      final json = {
        'id': 'o4',
        'restaurant_name': 'Test',
        'customer_address': 'Addr',
        'distance_km': 1.0,
        'base_earnings': 7.50,
        'bonus_earnings': 2.0,
        'status': 'pending',
        'created_at': '2026-02-10T12:00:00Z',
      };

      final order = Order.fromJson(json);
      expect(order.baseEarning, 7.50);
      expect(order.bonusEarning, 2.0);
    });
  });

  group('Order computed properties', () {
    late Order order;

    setUp(() {
      order = Order(
        id: 'test-1',
        restaurantName: 'Test Restaurant',
        customerAddress: 'Test Address',
        distanceKm: 3.0,
        baseEarning: 4.50,
        bonusEarning: 1.0,
        tipAmount: 2.0,
        rushMultiplier: 1.5,
        holdCost: 0.75,
        holdMinutes: 10,
        minGuarantee: 3.0,
        status: OrderStatus.pending,
        createdAt: DateTime(2026, 2, 10),
      );
    });

    test('totalEarning calculates correctly', () {
      // baseWithRush = 4.50 * 1.5 = 6.75
      // subtotal = 6.75 + 1.0 + 2.0 + 0.75 = 10.50
      expect(order.totalEarning, 10.50);
    });

    test('totalEarning applies minGuarantee when subtotal is lower', () {
      final lowOrder = Order(
        id: 'low-1',
        restaurantName: 'Test',
        customerAddress: 'Addr',
        distanceKm: 0.5,
        baseEarning: 0.5,
        rushMultiplier: 1.0,
        minGuarantee: 3.0,
        createdAt: DateTime(2026, 2, 10),
      );
      expect(lowOrder.totalEarning, 3.0);
      expect(lowOrder.minGuaranteeApplied, true);
    });

    test('baseWithRush calculates correctly', () {
      expect(order.baseWithRush, 6.75); // 4.50 * 1.5
    });

    test('rushBonus returns extra portion', () {
      expect(order.rushBonus, 2.25); // 4.50 * (1.5 - 1) = 2.25
    });

    test('rushBonus returns 0 when no rush', () {
      final noRush = Order(
        id: 't',
        restaurantName: 'T',
        customerAddress: 'A',
        distanceKm: 1.0,
        baseEarning: 5.0,
        rushMultiplier: 1.0,
        createdAt: DateTime.now(),
      );
      expect(noRush.rushBonus, 0);
      expect(noRush.isRushHour, false);
    });

    test('isRushHour returns true when multiplier > 1', () {
      expect(order.isRushHour, true);
    });

    test('estimatedMinutes calculates from distance', () {
      expect(order.estimatedMinutes, 12); // 3.0 * 4 = 12
    });

    test('distanceTier returns correct tier', () {
      expect(Order(
        id: 't1',
        restaurantName: 'T',
        customerAddress: 'A',
        distanceKm: 1.5,
        baseEarning: 3.0,
        createdAt: DateTime.now(),
      ).distanceTier, 'corta');

      expect(Order(
        id: 't2',
        restaurantName: 'T',
        customerAddress: 'A',
        distanceKm: 3.5,
        baseEarning: 5.0,
        createdAt: DateTime.now(),
      ).distanceTier, 'media');

      expect(Order(
        id: 't3',
        restaurantName: 'T',
        customerAddress: 'A',
        distanceKm: 7.0,
        baseEarning: 10.0,
        createdAt: DateTime.now(),
      ).distanceTier, 'lunga');
    });
  });

  group('Order.copyWithStatus', () {
    test('changes only the status', () {
      final original = Order(
        id: 'copy-1',
        restaurantName: 'Pizza Napoli',
        customerAddress: 'Via Dante 5',
        distanceKm: 3.0,
        baseEarning: 4.50,
        bonusEarning: 1.0,
        tipAmount: 2.0,
        rushMultiplier: 1.5,
        holdCost: 0.75,
        holdMinutes: 10,
        minGuarantee: 3.0,
        status: OrderStatus.pending,
        createdAt: DateTime(2026, 2, 10),
      );

      final accepted = original.copyWithStatus(OrderStatus.accepted);

      expect(accepted.status, OrderStatus.accepted);
      expect(accepted.id, original.id);
      expect(accepted.restaurantName, original.restaurantName);
      expect(accepted.baseEarning, original.baseEarning);
      expect(accepted.acceptedAt, isNotNull);
    });

    test('sets pickedUpAt when status is pickedUp', () {
      final order = Order(
        id: 'p1',
        restaurantName: 'T',
        customerAddress: 'A',
        distanceKm: 1.0,
        baseEarning: 3.0,
        status: OrderStatus.accepted,
        createdAt: DateTime.now(),
      );

      final pickedUp = order.copyWithStatus(OrderStatus.pickedUp);
      expect(pickedUp.pickedUpAt, isNotNull);
    });

    test('sets deliveredAt when status is delivered', () {
      final order = Order(
        id: 'd1',
        restaurantName: 'T',
        customerAddress: 'A',
        distanceKm: 1.0,
        baseEarning: 3.0,
        status: OrderStatus.pickedUp,
        createdAt: DateTime.now(),
      );

      final delivered = order.copyWithStatus(OrderStatus.delivered);
      expect(delivered.deliveredAt, isNotNull);
    });
  });

  group('Order.addTip', () {
    test('increments tipAmount', () {
      final order = Order(
        id: 'tip-1',
        restaurantName: 'T',
        customerAddress: 'A',
        distanceKm: 2.0,
        baseEarning: 3.0,
        tipAmount: 1.0,
        createdAt: DateTime.now(),
      );

      final tipped = order.addTip(2.50);
      expect(tipped.tipAmount, 3.50); // 1.0 + 2.50
      expect(tipped.id, order.id);
      expect(tipped.baseEarning, order.baseEarning);
    });
  });

  group('Order.updateHold', () {
    test('calculates hold cost from minutes and pricing', () {
      final pricing = const RiderPricing(
        holdCostPerMin: 0.15,
        holdFreeMinutes: 5,
      );

      final order = Order(
        id: 'hold-1',
        restaurantName: 'T',
        customerAddress: 'A',
        distanceKm: 2.0,
        baseEarning: 3.0,
        createdAt: DateTime.now(),
      );

      final updated = order.updateHold(10, pricing);
      // (10 - 5) * 0.15 = 0.75
      expect(updated.holdCost, 0.75);
      expect(updated.holdMinutes, 10);
    });
  });

  group('Order.toString', () {
    test('returns readable string', () {
      final order = Order(
        id: 'str-1',
        restaurantName: 'Pizza Express',
        customerAddress: 'Via Roma 10',
        distanceKm: 3.5,
        baseEarning: 5.25,
        minGuarantee: 3.0,
        createdAt: DateTime.now(),
      );

      final str = order.toString();
      expect(str, contains('str-1'));
      expect(str, contains('Pizza Express'));
      expect(str, contains('Via Roma 10'));
      expect(str, contains('3.5km'));
    });
  });

  group('Order.toJson', () {
    test('serializes correctly', () {
      final order = Order(
        id: 'json-1',
        restaurantName: 'Test',
        restaurantAddress: 'Addr1',
        customerName: 'Mario',
        customerAddress: 'Addr2',
        distanceKm: 2.5,
        baseEarning: 3.75,
        bonusEarning: 1.0,
        tipAmount: 0.5,
        rushMultiplier: 1.0,
        holdCost: 0.0,
        holdMinutes: 0,
        minGuarantee: 3.0,
        status: OrderStatus.delivered,
        createdAt: DateTime(2026, 2, 10, 12, 0),
        deliveredAt: DateTime(2026, 2, 10, 12, 30),
      );

      final json = order.toJson();
      expect(json['id'], 'json-1');
      expect(json['restaurant_name'], 'Test');
      expect(json['status'], 'delivered');
      expect(json['distance_tier'], 'media');
      expect(json['delivered_at'], isNotNull);
    });
  });
}
