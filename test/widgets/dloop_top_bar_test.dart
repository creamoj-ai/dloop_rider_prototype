import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/widgets/dloop_top_bar.dart';
import '../helpers/pump_helpers.dart';

void main() {
  group('DloopTopBar', () {
    testWidgets('renders search bar with custom hint', (tester) async {
      await tester.pumpWidget(testApp(
        const DloopTopBar(searchHint: 'Cerca zone...'),
      ));

      expect(find.text('Cerca zone...'), findsOneWidget);
    });

    testWidgets('renders default search hint', (tester) async {
      await tester.pumpWidget(testApp(
        const DloopTopBar(),
      ));

      expect(find.text('Cerca zone, ordini...'), findsOneWidget);
    });

    testWidgets('shows notification badge when count > 0', (tester) async {
      await tester.pumpWidget(testApp(
        const DloopTopBar(notificationCount: 5),
      ));

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows 9+ when notification count exceeds 9', (tester) async {
      await tester.pumpWidget(testApp(
        const DloopTopBar(notificationCount: 15),
      ));

      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('hides badge when notification count is 0', (tester) async {
      await tester.pumpWidget(testApp(
        const DloopTopBar(notificationCount: 0),
      ));

      // Badge text should not be present
      expect(find.text('0'), findsNothing);
    });

    testWidgets('renders bolt icon for quick actions', (tester) async {
      await tester.pumpWidget(testApp(
        const DloopTopBar(),
      ));

      expect(find.byIcon(Icons.bolt), findsOneWidget);
    });

    testWidgets('renders notification bell icon', (tester) async {
      await tester.pumpWidget(testApp(
        const DloopTopBar(),
      ));

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('renders search icon', (tester) async {
      await tester.pumpWidget(testApp(
        const DloopTopBar(),
      ));

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('renders person icon as default avatar', (tester) async {
      await tester.pumpWidget(testApp(
        const DloopTopBar(),
      ));

      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}
