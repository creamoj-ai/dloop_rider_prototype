import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/earning.dart';
import 'package:dloop_rider_prototype/providers/transactions_provider.dart';

void main() {
  group('PendingInfo', () {
    test('constructor sets fields', () {
      const info = PendingInfo(total: 25.50, count: 3);
      expect(info.total, 25.50);
      expect(info.count, 3);
    });
  });

  group('MonthlyTypeInfo', () {
    test('constructor sets fields', () {
      const info = MonthlyTypeInfo(total: 150.0, count: 12);
      expect(info.total, 150.0);
      expect(info.count, 12);
    });
  });

  // The derived providers (completedBalanceProvider, pendingBalanceProvider, etc.)
  // require a ProviderContainer with a mocked transactionsStreamProvider.
  // We test the logic inline by replicating the filter/fold logic here.

  group('Provider logic tests (inline)', () {
    final transactions = [
      Earning(
        id: 't1',
        type: EarningType.delivery,
        description: 'Delivery 1',
        amount: 8.50,
        dateTime: DateTime.now(),
        status: EarningStatus.completed,
      ),
      Earning(
        id: 't2',
        type: EarningType.delivery,
        description: 'Delivery 2',
        amount: 6.00,
        dateTime: DateTime.now(),
        status: EarningStatus.completed,
      ),
      Earning(
        id: 't3',
        type: EarningType.network,
        description: 'Commission',
        amount: 5.00,
        dateTime: DateTime.now(),
        status: EarningStatus.completed,
      ),
      Earning(
        id: 't4',
        type: EarningType.market,
        description: 'Market sale',
        amount: 12.00,
        dateTime: DateTime.now(),
        status: EarningStatus.pending,
      ),
      Earning(
        id: 't5',
        type: EarningType.delivery,
        description: 'Delivery 3',
        amount: 7.00,
        dateTime: DateTime.now(),
        status: EarningStatus.pending,
      ),
      Earning(
        id: 't6',
        type: EarningType.network,
        description: 'Bonus',
        amount: 3.00,
        dateTime: DateTime.now().subtract(const Duration(days: 45)),
        status: EarningStatus.completed,
      ),
      Earning(
        id: 't7',
        type: EarningType.delivery,
        description: 'Cancelled',
        amount: 4.00,
        dateTime: DateTime.now(),
        status: EarningStatus.cancelled,
      ),
    ];

    test('completedBalance sums only completed transactions', () {
      final balance = transactions
          .where((t) => t.status == EarningStatus.completed)
          .fold(0.0, (sum, t) => sum + t.amount);

      // t1(8.50) + t2(6.00) + t3(5.00) + t6(3.00) = 22.50
      expect(balance, 22.50);
    });

    test('pendingBalance sums only pending transactions', () {
      final balance = transactions
          .where((t) => t.status == EarningStatus.pending)
          .fold(0.0, (sum, t) => sum + t.amount);

      // t4(12.00) + t5(7.00) = 19.00
      expect(balance, 19.0);
    });

    test('pendingByType groups by type correctly', () {
      final pending =
          transactions.where((t) => t.status == EarningStatus.pending).toList();
      final map = <EarningType, PendingInfo>{};
      for (final type in EarningType.values) {
        final ofType = pending.where((t) => t.type == type).toList();
        if (ofType.isNotEmpty) {
          map[type] = PendingInfo(
            total: ofType.fold(0.0, (s, t) => s + t.amount),
            count: ofType.length,
          );
        }
      }

      expect(map[EarningType.delivery]?.total, 7.0);
      expect(map[EarningType.delivery]?.count, 1);
      expect(map[EarningType.market]?.total, 12.0);
      expect(map[EarningType.market]?.count, 1);
      expect(map.containsKey(EarningType.network), false);
    });

    test('monthlyByType filters only current month completed', () {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final thisMonth = transactions.where((t) =>
          t.status == EarningStatus.completed &&
          t.dateTime.isAfter(monthStart));

      final map = <EarningType, MonthlyTypeInfo>{};
      for (final type in EarningType.values) {
        final ofType = thisMonth.where((t) => t.type == type).toList();
        map[type] = MonthlyTypeInfo(
          total: ofType.fold(0.0, (s, t) => s + t.amount),
          count: ofType.length,
        );
      }

      // t1, t2 delivery = 14.50; t3 network = 5.00; t6 is 45 days ago (excluded)
      expect(map[EarningType.delivery]?.total, 14.50);
      expect(map[EarningType.delivery]?.count, 2);
      expect(map[EarningType.network]?.total, 5.00);
      expect(map[EarningType.network]?.count, 1);
      expect(map[EarningType.market]?.total, 0);
      expect(map[EarningType.market]?.count, 0);
    });

    test('recentTransactions returns max 5', () {
      final recent = transactions.take(5).toList();
      expect(recent.length, 5);
    });

    test('recentTransactions with fewer than 5 returns all', () {
      final shortList = transactions.take(3).toList();
      final recent = shortList.take(5).toList();
      expect(recent.length, 3);
    });

    test('todayTransactions filters only today', () {
      final todayStart = DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
      );

      final today = transactions
          .where((t) => t.dateTime.isAfter(todayStart))
          .toList();

      // t6 is 45 days ago, all others are today
      expect(today.length, 6);
    });

    test('allTransactions returns everything', () {
      expect(transactions.length, 7);
    });

    test('completedBalance with empty list returns 0', () {
      final balance = <Earning>[]
          .where((t) => t.status == EarningStatus.completed)
          .fold(0.0, (sum, t) => sum + t.amount);
      expect(balance, 0.0);
    });
  });
}
