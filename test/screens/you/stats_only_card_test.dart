import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/screens/you/widgets/stats_only_card.dart';
import 'package:dloop_rider_prototype/providers/rider_stats_provider.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  group('StatsOnlyCard', () {
    final testStats = RiderStats.fromJson({
      'lifetime_orders': 1247,
      'lifetime_earnings': 8500.00,
      'lifetime_distance_km': 2300.0,
      'lifetime_hours_online': 350.0,
      'avg_rating': 4.80,
      'best_day_earnings': 150.00,
    });

    testWidgets('renders STATISTICHE LIFETIME header', (tester) async {
      await tester.pumpWidget(testApp(
        const StatsOnlyCard(),
        overrides: [
          riderStatsProvider.overrideWith((ref) async => testStats),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('STATISTICHE LIFETIME'), findsOneWidget);
    });

    testWidgets('renders all 6 stat labels', (tester) async {
      await tester.pumpWidget(testApp(
        const StatsOnlyCard(),
        overrides: [
          riderStatsProvider.overrideWith((ref) async => testStats),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Ordini totali'), findsOneWidget);
      expect(find.text('Guadagno totale'), findsOneWidget);
      expect(find.text('Km percorsi'), findsOneWidget);
      expect(find.text('Rating medio'), findsOneWidget);
      expect(find.text('Best day'), findsOneWidget);
      expect(find.text('Ore totali'), findsOneWidget);
    });

    testWidgets('formats large numbers with dot separator', (tester) async {
      await tester.pumpWidget(testApp(
        const StatsOnlyCard(),
        overrides: [
          riderStatsProvider.overrideWith((ref) async => testStats),
        ],
      ));
      await tester.pumpAndSettle();

      // 1247 → "1.247"
      expect(find.text('1.247'), findsOneWidget);
      // 8500 → "€ 8.500"
      expect(find.text('€ 8.500'), findsOneWidget);
      // 2300 → "2.300"
      expect(find.text('2.300'), findsOneWidget);
    });

    testWidgets('renders with default values during loading', (tester) async {
      // Use a Completer that never completes — stays in loading state
      // without creating a Timer (avoids "Timer is still pending" error)
      final completer = Completer<RiderStats>();
      await tester.pumpWidget(testApp(
        const StatsOnlyCard(),
        overrides: [
          riderStatsProvider.overrideWith(
            (ref) => completer.future,
          ),
        ],
      ));
      // Don't pumpAndSettle — test the loading/default state
      await tester.pump();

      expect(find.text('STATISTICHE LIFETIME'), findsOneWidget);
      // Default RiderStats() has all zeros
      expect(find.text('Ordini totali'), findsOneWidget);
    });
  });
}
