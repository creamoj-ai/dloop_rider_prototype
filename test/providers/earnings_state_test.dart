import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/order.dart';
import 'package:dloop_rider_prototype/models/daily_target.dart';
import 'package:dloop_rider_prototype/models/earning.dart';
import 'package:dloop_rider_prototype/providers/earnings_provider.dart';

void main() {
  Order _delivered({
    required double base,
    double bonus = 0,
    double tip = 0,
    double rush = 1.0,
    double hold = 0,
    double distance = 2.0,
    DateTime? deliveredAt,
  }) {
    return Order(
      id: 'o-${base.hashCode}',
      restaurantName: 'Test',
      customerAddress: 'Addr',
      distanceKm: distance,
      baseEarning: base,
      bonusEarning: bonus,
      tipAmount: tip,
      rushMultiplier: rush,
      holdCost: hold,
      status: OrderStatus.delivered,
      createdAt: DateTime(2026, 2, 10, 10),
      deliveredAt: deliveredAt ?? DateTime(2026, 2, 10, 12),
    );
  }

  group('EarningsState', () {
    test('default state has empty orders and isOnline false', () {
      final state = EarningsState(
        dailyTarget: DailyTarget(date: DateTime(2026, 2, 10)),
      );

      expect(state.todayOrders, isEmpty);
      expect(state.isOnline, false);
      expect(state.activeOrder, isNull);
      expect(state.totalKmToday, 0);
    });

    group('todayTotal', () {
      test('returns dailyTarget.currentAmount', () {
        final state = EarningsState(
          dailyTarget: DailyTarget(
            date: DateTime(2026, 2, 10),
            currentAmount: 45.50,
          ),
        );

        expect(state.todayTotal, 45.50);
      });
    });

    group('ordersCount', () {
      test('counts only delivered orders', () {
        final state = EarningsState(
          dailyTarget: DailyTarget(date: DateTime(2026, 2, 10)),
          todayOrders: [
            _delivered(base: 5.0),
            _delivered(base: 3.0),
            Order(
              id: 'pending-1',
              restaurantName: 'T',
              customerAddress: 'A',
              distanceKm: 1.0,
              baseEarning: 3.0,
              status: OrderStatus.pending,
              createdAt: DateTime(2026, 2, 10),
            ),
            Order(
              id: 'cancelled-1',
              restaurantName: 'T',
              customerAddress: 'A',
              distanceKm: 1.0,
              baseEarning: 3.0,
              status: OrderStatus.cancelled,
              createdAt: DateTime(2026, 2, 10),
            ),
          ],
        );

        expect(state.ordersCount, 2);
      });

      test('returns 0 with empty list', () {
        final state = EarningsState(
          dailyTarget: DailyTarget(date: DateTime(2026, 2, 10)),
        );
        expect(state.ordersCount, 0);
      });
    });

    group('avgPerOrder', () {
      test('calculates average', () {
        final state = EarningsState(
          dailyTarget: DailyTarget(
            date: DateTime(2026, 2, 10),
            currentAmount: 30.0,
          ),
          todayOrders: [
            _delivered(base: 10.0),
            _delivered(base: 10.0),
            _delivered(base: 10.0),
          ],
        );

        expect(state.avgPerOrder, 10.0);
      });

      test('returns 0 with 0 delivered orders', () {
        final state = EarningsState(
          dailyTarget: DailyTarget(
            date: DateTime(2026, 2, 10),
            currentAmount: 0,
          ),
        );

        expect(state.avgPerOrder, 0);
      });
    });

    group('hasActiveOrder', () {
      test('returns false when no active order', () {
        final state = EarningsState(
          dailyTarget: DailyTarget(date: DateTime(2026, 2, 10)),
        );
        expect(state.hasActiveOrder, false);
      });

      test('returns true when active order exists', () {
        final state = EarningsState(
          dailyTarget: DailyTarget(date: DateTime(2026, 2, 10)),
          activeOrder: Order(
            id: 'active-1',
            restaurantName: 'T',
            customerAddress: 'A',
            distanceKm: 2.0,
            baseEarning: 3.0,
            status: OrderStatus.accepted,
            createdAt: DateTime.now(),
          ),
        );
        expect(state.hasActiveOrder, true);
      });
    });

    group('todayBreakdown', () {
      test('sums breakdown from delivered orders', () {
        final state = EarningsState(
          dailyTarget: DailyTarget(date: DateTime(2026, 2, 10)),
          todayOrders: [
            _delivered(base: 5.0, bonus: 1.0, tip: 2.0, rush: 2.0, hold: 0.5),
            _delivered(base: 3.0, bonus: 0.5, tip: 1.0, rush: 1.0, hold: 0.0),
            // non-delivered should be excluded
            Order(
              id: 'pending',
              restaurantName: 'T',
              customerAddress: 'A',
              distanceKm: 1.0,
              baseEarning: 10.0,
              bonusEarning: 5.0,
              tipAmount: 3.0,
              status: OrderStatus.pending,
              createdAt: DateTime(2026, 2, 10),
            ),
          ],
        );

        final breakdown = state.todayBreakdown;
        expect(breakdown['base'], 8.0); // 5+3
        expect(breakdown['bonus'], 1.5); // 1+0.5
        expect(breakdown['tips'], 3.0); // 2+1
        // rush bonus: first order = 5.0*(2.0-1)=5.0, second=0
        expect(breakdown['rush'], 5.0);
        expect(breakdown['hold'], 0.5);
      });

      test('returns zeros with no delivered orders', () {
        final state = EarningsState(
          dailyTarget: DailyTarget(date: DateTime(2026, 2, 10)),
        );

        final breakdown = state.todayBreakdown;
        expect(breakdown['base'], 0);
        expect(breakdown['bonus'], 0);
        expect(breakdown['tips'], 0);
        expect(breakdown['rush'], 0);
        expect(breakdown['hold'], 0);
        expect(breakdown['total'], 0);
      });
    });

    group('copyWith', () {
      test('overwrites specified fields', () {
        final state = EarningsState(
          dailyTarget: DailyTarget(date: DateTime(2026, 2, 10)),
          isOnline: false,
          totalKmToday: 10.0,
        );

        final updated = state.copyWith(
          isOnline: true,
          totalKmToday: 25.0,
        );

        expect(updated.isOnline, true);
        expect(updated.totalKmToday, 25.0);
        expect(updated.todayOrders, state.todayOrders);
      });

      test('clearActiveOrder sets activeOrder to null', () {
        final state = EarningsState(
          dailyTarget: DailyTarget(date: DateTime(2026, 2, 10)),
          activeOrder: Order(
            id: 'active',
            restaurantName: 'T',
            customerAddress: 'A',
            distanceKm: 1.0,
            baseEarning: 3.0,
            createdAt: DateTime.now(),
          ),
        );

        final cleared = state.copyWith(clearActiveOrder: true);
        expect(cleared.activeOrder, isNull);
      });
    });
  });

  group('NetworkEarningsState', () {
    test('default state', () {
      const state = NetworkEarningsState();
      expect(state.networkEarnings, isEmpty);
      expect(state.notifiedCount, 0);
    });

    test('copyWith', () {
      final earnings = [
        Earning(
          id: 'e1',
          type: EarningType.network,
          description: 'Commission',
          amount: 5.0,
          dateTime: DateTime.now(),
          status: EarningStatus.completed,
        ),
      ];

      const state = NetworkEarningsState();
      final updated = state.copyWith(
        networkEarnings: earnings,
        notifiedCount: 1,
      );

      expect(updated.networkEarnings.length, 1);
      expect(updated.notifiedCount, 1);
    });
  });
}
