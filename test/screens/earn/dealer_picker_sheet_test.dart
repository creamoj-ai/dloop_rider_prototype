import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dloop_rider_prototype/models/rider_contact.dart';
import 'package:dloop_rider_prototype/providers/contacts_provider.dart';
import 'package:dloop_rider_prototype/screens/earn/widgets/dealer_picker_sheet.dart';

final _mockDealers = [
  RiderContact(
    id: 'd1',
    riderId: 'r1',
    name: 'Pizzeria Da Mario',
    contactType: 'dealer',
    status: 'active',
    phone: '+393331234567',
    totalOrders: 15,
    createdAt: DateTime(2026, 1, 1),
  ),
  RiderContact(
    id: 'd2',
    riderId: 'r1',
    name: 'Sushi Zen',
    contactType: 'dealer',
    status: 'potential',
    phone: '+393339876543',
    totalOrders: 3,
    createdAt: DateTime(2026, 1, 15),
  ),
  RiderContact(
    id: 'd3',
    riderId: 'r1',
    name: 'Farmacia Centrale',
    contactType: 'dealer',
    status: 'active',
    totalOrders: 8,
    createdAt: DateTime(2026, 2, 1),
  ),
];

Widget _buildTestWidget({List<RiderContact>? dealers}) {
  GoogleFonts.config.allowRuntimeFetching = false;
  final dealerList = dealers ?? _mockDealers;

  return ProviderScope(
    overrides: [
      dealersProvider.overrideWith(
        (ref) => AsyncValue.data(dealerList),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDealerPickerSheet(context),
            child: const Text('Open Picker'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('DealerPickerSheet', () {
    testWidgets('renders dealer list', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Seleziona Dealer'), findsOneWidget);
      expect(find.text('Pizzeria Da Mario'), findsOneWidget);
      expect(find.text('Sushi Zen'), findsOneWidget);
      expect(find.text('Farmacia Centrale'), findsOneWidget);
    });

    testWidgets('shows search field', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Cerca dealer...'), findsOneWidget);
    });

    testWidgets('search field accepts input without crash', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Verify search field exists
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Entering text should not throw
      await tester.enterText(textField, 'pizza');
      await tester.pump();
      // Sheet rebuilds without crashing
    });

    testWidgets('shows active/potential badges', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Active dealers show "Attivo", potential show "Potenziale"
      expect(find.text('Attivo'), findsNWidgets(2)); // d1 and d3
      expect(find.text('Potenziale'), findsOneWidget); // d2
    });

    testWidgets('shows empty state when no dealers', (tester) async {
      await tester.pumpWidget(_buildTestWidget(dealers: []));
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nessun dealer'), findsOneWidget);
    });

    testWidgets('shows order count per dealer', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('+393331234567 \u2022 15 ordini'), findsOneWidget);
      expect(find.text('+393339876543 \u2022 3 ordini'), findsOneWidget);
    });
  });
}
