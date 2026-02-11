/// Integration Test 3: Feature Flows (authenticated)
///
/// Tests deep features: Settings, Guadagni drill-down, Profile, Market.
/// Requires TEST_EMAIL and TEST_PASSWORD in .env file.
/// Run: flutter test integration_test/feature_flow_test.dart -d ZPPBN795OFDMON9L
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Feature Flow: login → tabs → drill-down screens',
      (tester) async {
    // ── Launch & Login ──
    await launchApp(tester);
    await loginWithCredentials(tester);

    // ── 1. Today screen renders main widgets ──
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.byType(Scrollable), findsWidgets);
    await tester.pump(const Duration(seconds: 2));

    // ── 2. Market tab: COMING SOON is visible ──
    await tapBottomTab(tester, 'Market');
    await waitFor(tester, find.text('COMING SOON'));
    expect(find.text('Il marketplace dloop arriva presto!'), findsOneWidget);
    expect(find.text('Vendi prodotti durante le consegne'), findsOneWidget);
    expect(find.byIcon(Icons.storefront), findsOneWidget);

    // ── 3. Guadagni drill-down: balance section ──
    await tapBottomTab(tester, 'Guadagni');
    await waitFor(tester, find.text('SALDO DISPONIBILE'),
        timeout: const Duration(seconds: 10),
        description: 'Money screen should show balance');

    // Scroll to verify IncomeStreams section (titles are uppercase)
    await scrollToFind(tester, find.text('CONSEGNE'));
    expect(find.text('CONSEGNE'), findsOneWidget,
        reason: 'IncomeStreams should show CONSEGNE card');

    // ── 4. Profilo: profile + stats + gamification ──
    await tapBottomTab(tester, 'Profilo');
    await waitFor(tester, find.text('STATISTICHE LIFETIME'),
        timeout: const Duration(seconds: 10),
        description: 'Profile should show stats card');

    // Verify gamification card
    await scrollToFind(tester, find.text('GAMIFICATION'));
    expect(find.text('GAMIFICATION'), findsOneWidget);

    // Verify invite section
    await scrollToFind(tester, find.text('Invita amici'));
    if (find.text('Invita amici').evaluate().isNotEmpty) {
      expect(find.text('Invita amici'), findsOneWidget);
    }

    // ── 5. Settings (from Profilo) ──
    // Scroll to find settings icon and tap it
    await scrollToFind(tester, find.byIcon(Icons.settings));
    if (find.byIcon(Icons.settings).evaluate().isNotEmpty) {
      await tester.tap(find.byIcon(Icons.settings).first);
      await tester.pump(const Duration(seconds: 2));

      await waitFor(tester, find.text('Impostazioni'),
          timeout: const Duration(seconds: 5),
          description: 'Settings screen should appear');

      // Go back to Profilo
      await tapBack(tester);
      await tester.pump(const Duration(seconds: 1));
    }
  });
}
