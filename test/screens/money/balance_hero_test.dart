import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/screens/money/widgets/balance_hero.dart';
import 'package:dloop_rider_prototype/providers/transactions_provider.dart';
import 'package:dloop_rider_prototype/models/earning.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  group('BalanceHero', () {
    testWidgets('renders SALDO DISPONIBILE label', (tester) async {
      await tester.pumpWidget(testApp(
        const BalanceHero(),
        overrides: [
          completedBalanceProvider.overrideWith((ref) => 0.0),
          pendingBalanceProvider.overrideWith((ref) => 0.0),
          pendingByTypeProvider.overrideWith(
            (ref) => <EarningType, PendingInfo>{},
          ),
        ],
      ));

      expect(find.text('SALDO DISPONIBILE'), findsOneWidget);
    });

    testWidgets('formats balance in Italian style', (tester) async {
      await tester.pumpWidget(testApp(
        const BalanceHero(),
        overrides: [
          completedBalanceProvider.overrideWith((ref) => 1847.50),
          pendingBalanceProvider.overrideWith((ref) => 0.0),
          pendingByTypeProvider.overrideWith(
            (ref) => <EarningType, PendingInfo>{},
          ),
        ],
      ));

      // 1847.50 → "€ 1.847,50"
      expect(find.text('€ 1.847,50'), findsOneWidget);
    });

    testWidgets('formats zero balance', (tester) async {
      await tester.pumpWidget(testApp(
        const BalanceHero(),
        overrides: [
          completedBalanceProvider.overrideWith((ref) => 0.0),
          pendingBalanceProvider.overrideWith((ref) => 0.0),
          pendingByTypeProvider.overrideWith(
            (ref) => <EarningType, PendingInfo>{},
          ),
        ],
      ));

      expect(find.text('€ 0,00'), findsOneWidget);
    });

    testWidgets('hides pending card when pending is 0', (tester) async {
      await tester.pumpWidget(testApp(
        const BalanceHero(),
        overrides: [
          completedBalanceProvider.overrideWith((ref) => 100.0),
          pendingBalanceProvider.overrideWith((ref) => 0.0),
          pendingByTypeProvider.overrideWith(
            (ref) => <EarningType, PendingInfo>{},
          ),
        ],
      ));

      // No pending card should be rendered
      expect(find.byIcon(Icons.schedule), findsNothing);
      expect(find.textContaining('in arrivo'), findsNothing);
    });

    testWidgets('shows pending card when pending > 0', (tester) async {
      await tester.pumpWidget(testApp(
        const BalanceHero(),
        overrides: [
          completedBalanceProvider.overrideWith((ref) => 100.0),
          pendingBalanceProvider.overrideWith((ref) => 25.00),
          pendingByTypeProvider.overrideWith(
            (ref) => {
              EarningType.delivery: const PendingInfo(total: 25.0, count: 2),
            },
          ),
        ],
      ));

      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.text('+€ 25.00 in arrivo'), findsOneWidget);
    });

    testWidgets('expands pending card on tap to show type breakdown', (tester) async {
      await tester.pumpWidget(testApp(
        const BalanceHero(),
        overrides: [
          completedBalanceProvider.overrideWith((ref) => 100.0),
          pendingBalanceProvider.overrideWith((ref) => 37.00),
          pendingByTypeProvider.overrideWith(
            (ref) => {
              EarningType.delivery: const PendingInfo(total: 25.0, count: 2),
              EarningType.network: const PendingInfo(total: 12.0, count: 1),
            },
          ),
        ],
      ));

      // Tap to expand pending breakdown
      await tester.tap(find.text('+€ 37.00 in arrivo'));
      await tester.pumpAndSettle();

      // Should show type breakdown
      expect(find.text('Consegne'), findsOneWidget);
      expect(find.text('Network'), findsOneWidget);
      expect(find.text('€25.00'), findsOneWidget);
      expect(find.text('€12.00'), findsOneWidget);
      expect(find.text('2 in elaborazione'), findsOneWidget);
      expect(find.text('1 in elaborazione'), findsOneWidget);
    });
  });
}
