import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/screens/market/market_tab_screen.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  group('MarketTabScreen', () {
    testWidgets('renders COMING SOON overlay', (tester) async {
      await tester.pumpWidget(testScreen(const MarketTabScreen()));

      expect(find.text('COMING SOON'), findsOneWidget);
    });

    testWidgets('renders marketplace description', (tester) async {
      await tester.pumpWidget(testScreen(const MarketTabScreen()));

      expect(find.text('Il marketplace dloop arriva presto!'), findsOneWidget);
      expect(find.text('Vendi prodotti durante le consegne'), findsOneWidget);
    });

    testWidgets('renders storefront icon', (tester) async {
      await tester.pumpWidget(testScreen(const MarketTabScreen()));

      expect(find.byIcon(Icons.storefront), findsOneWidget);
    });

    testWidgets('content is faded with opacity 0.25', (tester) async {
      await tester.pumpWidget(testScreen(const MarketTabScreen()));

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.25);
    });

    testWidgets('content is non-interactive via IgnorePointer', (tester) async {
      await tester.pumpWidget(testScreen(const MarketTabScreen()));

      // The IgnorePointer wrapping the faded content is a descendant of Opacity
      final opacityFinder = find.byType(Opacity);
      final opacity = tester.widget<Opacity>(opacityFinder);
      expect(opacity.child, isA<IgnorePointer>());
    });
  });
}
