import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/daily_target.dart';

void main() {
  group('DailyTarget', () {
    test('default values', () {
      final target = DailyTarget(date: DateTime(2026, 2, 10));

      expect(target.targetAmount, 80.0);
      expect(target.currentAmount, 0.0);
      expect(target.ordersCompleted, 0);
    });

    group('progress', () {
      test('returns 0 when currentAmount is 0', () {
        final target = DailyTarget(date: DateTime(2026, 2, 10));
        expect(target.progress, 0.0);
      });

      test('returns 0.5 at halfway', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 100.0,
          currentAmount: 50.0,
        );
        expect(target.progress, 0.5);
      });

      test('clamps to 1.0 when over target', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 80.0,
          currentAmount: 120.0,
        );
        expect(target.progress, 1.0);
      });

      test('returns 0 when targetAmount is 0', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 0,
          currentAmount: 50.0,
        );
        expect(target.progress, 0.0);
      });
    });

    group('progressPercent', () {
      test('returns 0 to 100', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 100.0,
          currentAmount: 75.0,
        );
        expect(target.progressPercent, 75);
      });
    });

    group('remaining', () {
      test('calculates remaining amount', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 100.0,
          currentAmount: 65.0,
        );
        expect(target.remaining, 35.0);
      });

      test('clamps to 0 when over target', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 80.0,
          currentAmount: 120.0,
        );
        expect(target.remaining, 0.0);
      });
    });

    group('isComplete', () {
      test('returns false when below target', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 80.0,
          currentAmount: 50.0,
        );
        expect(target.isComplete, false);
      });

      test('returns true when at target', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 80.0,
          currentAmount: 80.0,
        );
        expect(target.isComplete, true);
      });

      test('returns true when over target', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 80.0,
          currentAmount: 100.0,
        );
        expect(target.isComplete, true);
      });
    });

    group('avgPerOrder', () {
      test('calculates average per order', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          currentAmount: 30.0,
          ordersCompleted: 3,
        );
        expect(target.avgPerOrder, 10.0);
      });

      test('returns 0 with 0 orders', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          currentAmount: 0.0,
          ordersCompleted: 0,
        );
        expect(target.avgPerOrder, 0.0);
      });
    });

    group('estimatedOrdersToComplete', () {
      test('estimates orders needed', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 100.0,
          currentAmount: 30.0,
          ordersCompleted: 3,
        );
        // remaining = 70, avgPerOrder = 10 → 7
        expect(target.estimatedOrdersToComplete, 7);
      });

      test('returns 0 when complete', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 80.0,
          currentAmount: 80.0,
          ordersCompleted: 8,
        );
        expect(target.estimatedOrdersToComplete, 0);
      });

      test('returns 0 when avgPerOrder is 0', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 80.0,
          currentAmount: 0.0,
          ordersCompleted: 0,
        );
        expect(target.estimatedOrdersToComplete, 0);
      });

      test('rounds up with ceil', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 100.0,
          currentAmount: 25.0,
          ordersCompleted: 3,
        );
        // remaining = 75, avgPerOrder = 8.33 → 75/8.33 = 9.0 → ceil = 9
        expect(target.estimatedOrdersToComplete, 9);
      });
    });

    group('addEarning', () {
      test('increments currentAmount and ordersCompleted', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          currentAmount: 20.0,
          ordersCompleted: 2,
        );

        final updated = target.addEarning(8.50);

        expect(updated.currentAmount, 28.50);
        expect(updated.ordersCompleted, 3);
        expect(updated.targetAmount, target.targetAmount);
        expect(updated.date, target.date);
      });

      test('can exceed targetAmount', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 80.0,
          currentAmount: 75.0,
          ordersCompleted: 8,
        );

        final updated = target.addEarning(10.0);
        expect(updated.currentAmount, 85.0);
        expect(updated.isComplete, true);
      });
    });

    group('resetForNewDay', () {
      test('resets currentAmount and ordersCompleted', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 100.0,
          currentAmount: 65.0,
          ordersCompleted: 7,
        );

        final reset = target.resetForNewDay();

        expect(reset.currentAmount, 0.0);
        expect(reset.ordersCompleted, 0);
        expect(reset.targetAmount, 100.0);
      });
    });

    group('copyWith', () {
      test('overwrites specified fields', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 80.0,
          currentAmount: 30.0,
          ordersCompleted: 3,
        );

        final updated = target.copyWith(targetAmount: 120.0);

        expect(updated.targetAmount, 120.0);
        expect(updated.currentAmount, 30.0);
        expect(updated.ordersCompleted, 3);
      });
    });

    group('toString', () {
      test('returns readable string', () {
        final target = DailyTarget(
          date: DateTime(2026, 2, 10),
          targetAmount: 100.0,
          currentAmount: 50.0,
          ordersCompleted: 5,
        );

        final str = target.toString();
        expect(str, contains('50.0'));
        expect(str, contains('100.0'));
        expect(str, contains('5'));
        expect(str, contains('50%'));
      });
    });
  });
}
