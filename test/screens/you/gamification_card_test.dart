import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/screens/you/widgets/expandable_gamification_card.dart';
import 'package:dloop_rider_prototype/providers/rider_stats_provider.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  group('ExpandableGamificationCard', () {
    final testStats = RiderStats.fromJson({
      'current_level': 5,
      'current_xp': 250,
      'xp_to_next_level': 500,
      'current_daily_streak': 7,
      'achievements_unlocked': 3,
      'lifetime_orders': 150,
      'lifetime_earnings': 2000.0,
    });

    testWidgets('renders GAMIFICATION title', (tester) async {
      await tester.pumpWidget(testApp(
        const ExpandableGamificationCard(),
        overrides: [
          riderStatsProvider.overrideWith((ref) async => testStats),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('GAMIFICATION'), findsOneWidget);
    });

    testWidgets('shows current level', (tester) async {
      await tester.pumpWidget(testApp(
        const ExpandableGamificationCard(),
        overrides: [
          riderStatsProvider.overrideWith((ref) async => testStats),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Lv 5'), findsOneWidget);
    });

    testWidgets('renders XP progress bar when collapsed', (tester) async {
      await tester.pumpWidget(testApp(
        const ExpandableGamificationCard(),
        overrides: [
          riderStatsProvider.overrideWith((ref) async => testStats),
        ],
      ));
      await tester.pumpAndSettle();

      // AnimatedCrossFade renders both children in the tree, so there are 2
      // LinearProgressIndicators (header inline + expanded section)
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('renders trophy icon', (tester) async {
      await tester.pumpWidget(testApp(
        const ExpandableGamificationCard(),
        overrides: [
          riderStatsProvider.overrideWith((ref) async => testStats),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events), findsWidgets);
    });

    testWidgets('AnimatedCrossFade starts in collapsed state', (tester) async {
      await tester.pumpWidget(testApp(
        const ExpandableGamificationCard(),
        overrides: [
          riderStatsProvider.overrideWith((ref) async => testStats),
        ],
      ));
      await tester.pumpAndSettle();

      final crossFade = tester.widget<AnimatedCrossFade>(
        find.byType(AnimatedCrossFade),
      );
      expect(crossFade.crossFadeState, CrossFadeState.showFirst);
    });

    testWidgets('tap expands card (AnimatedCrossFade shows second)', (tester) async {
      await tester.pumpWidget(testApp(
        const ExpandableGamificationCard(),
        overrides: [
          riderStatsProvider.overrideWith((ref) async => testStats),
        ],
      ));
      await tester.pumpAndSettle();

      // Tap the InkWell to expand
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      final crossFade = tester.widget<AnimatedCrossFade>(
        find.byType(AnimatedCrossFade),
      );
      expect(crossFade.crossFadeState, CrossFadeState.showSecond);
    });

    testWidgets('renders expand/collapse arrow icon', (tester) async {
      await tester.pumpWidget(testApp(
        const ExpandableGamificationCard(),
        overrides: [
          riderStatsProvider.overrideWith((ref) async => testStats),
        ],
      ));
      await tester.pumpAndSettle();

      // Collapsed: shows arrow down
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

      // Tap to expand
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      // Expanded: shows arrow up
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    });
  });
}
