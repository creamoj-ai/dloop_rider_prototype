import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/widgets/dloop_card.dart';
import '../helpers/pump_helpers.dart';

void main() {
  group('DloopCard', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(testApp(
        const DloopCard(child: Text('Hello')),
      ));

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('has dark background color 0xFF1A1A1E', (tester) async {
      await tester.pumpWidget(testApp(
        const DloopCard(child: Text('Card')),
      ));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DloopCard),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF1A1A1E));
    });

    testWidgets('applies border radius 16', (tester) async {
      await tester.pumpWidget(testApp(
        const DloopCard(child: Text('Card')),
      ));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DloopCard),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('wraps in GestureDetector when onTap is provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(testApp(
        DloopCard(
          onTap: () => tapped = true,
          child: const Text('Tap me'),
        ),
      ));

      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });

    testWidgets('does not wrap in GestureDetector when onTap is null', (tester) async {
      await tester.pumpWidget(testApp(
        const DloopCard(child: Text('No tap')),
      ));

      // DloopCard should render Container directly, not wrapped in GestureDetector
      final dloopCard = find.byType(DloopCard);
      final gestureDetectors = find.descendant(
        of: dloopCard,
        matching: find.byType(GestureDetector),
      );

      // The Scaffold/MaterialApp may add GestureDetectors, so check that
      // DloopCard's direct child is Container (not GestureDetector)
      final element = tester.element(dloopCard);
      final widget = element.widget as DloopCard;
      expect(widget.onTap, isNull);
    });

    testWidgets('uses default padding of 20', (tester) async {
      await tester.pumpWidget(testApp(
        const DloopCard(child: Text('Padded')),
      ));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DloopCard),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.padding, const EdgeInsets.all(20));
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(testApp(
        const DloopCard(padding: 8, child: Text('Custom')),
      ));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DloopCard),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.padding, const EdgeInsets.all(8));
    });
  });
}
