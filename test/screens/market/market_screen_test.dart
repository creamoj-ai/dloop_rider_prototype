import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/market_product.dart';
import 'package:dloop_rider_prototype/models/market_order.dart';
import 'package:dloop_rider_prototype/providers/market_products_provider.dart';
import 'package:dloop_rider_prototype/providers/market_orders_provider.dart';
import 'package:dloop_rider_prototype/screens/market/market_tab_screen.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  group('MarketTabScreen', () {
    final now = DateTime(2026, 2, 11);
    final mockProducts = [
      MarketProduct(
        id: 'p1', name: 'Energy Drink', price: 15.0, costPrice: 8.0,
        category: 'bevande', stock: 10, createdAt: now, updatedAt: now,
      ),
      MarketProduct(
        id: 'p2', name: 'Snack Box', price: 12.0, costPrice: 5.0,
        category: 'food', stock: 5, createdAt: now, updatedAt: now,
      ),
    ];

    final mockOrders = [
      MarketOrder(
        id: 'o1', productName: 'Energy Drink', customerName: 'Anna V.',
        unitPrice: 15.0, totalPrice: 15.0, status: MarketOrderStatus.pending,
        createdAt: now,
      ),
    ];

    List<Override> overrides() => [
      marketProductsStreamProvider.overrideWith(
        (ref) => Stream.value(mockProducts),
      ),
      marketOrdersStreamProvider.overrideWith(
        (ref) => Stream.value(mockOrders),
      ),
    ];

    testWidgets('renders KPI row with real data', (tester) async {
      await tester.pumpWidget(testScreen(
        const MarketTabScreen(),
        overrides: overrides(),
      ));
      await tester.pumpAndSettle();

      // Product count
      expect(find.text('2'), findsOneWidget);
      // Labels
      expect(find.text('Prodotti'), findsOneWidget);
      expect(find.text('Ordini'), findsOneWidget);
      expect(find.text('Guadagni'), findsOneWidget);
    });

    testWidgets('renders product cards from providers', (tester) async {
      await tester.pumpWidget(testScreen(
        const MarketTabScreen(),
        overrides: overrides(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Energy Drink'), findsOneWidget);
      expect(find.text('Snack Box'), findsOneWidget);
    });

    testWidgets('renders active orders', (tester) async {
      await tester.pumpWidget(testScreen(
        const MarketTabScreen(),
        overrides: overrides(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Anna V.'), findsOneWidget);
      expect(find.text('Nuovo'), findsOneWidget);
    });

    testWidgets('shows FAB for adding products', (tester) async {
      await tester.pumpWidget(testScreen(
        const MarketTabScreen(),
        overrides: overrides(),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows empty state when no products', (tester) async {
      await tester.pumpWidget(testScreen(
        const MarketTabScreen(),
        overrides: [
          marketProductsStreamProvider.overrideWith(
            (ref) => Stream.value(<MarketProduct>[]),
          ),
          marketOrdersStreamProvider.overrideWith(
            (ref) => Stream.value(<MarketOrder>[]),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Nessun prodotto'), findsOneWidget);
      expect(find.text('Nessun ordine attivo'), findsOneWidget);
    });
  });
}
