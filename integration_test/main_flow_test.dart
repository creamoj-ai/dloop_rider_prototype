/// Integration Test 2: Main Navigation Flow (authenticated)
///
/// Tests login → navigate all 4 tabs → verify each screen renders.
/// Requires TEST_EMAIL and TEST_PASSWORD in .env file.
/// Run: flutter test integration_test/main_flow_test.dart -d ZPPBN795OFDMON9L
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Main Flow: login → navigate all tabs → sub-screens',
      (tester) async {
    // ── Launch & Login ──
    await launchApp(tester);
    await loginWithCredentials(tester);

    // ── 1. OGGI tab (default after login) ──
    // Bottom nav should show all 4 tab labels
    expect(find.text('Oggi'), findsOneWidget);
    expect(find.text('Guadagni'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Profilo'), findsOneWidget);

    // Today screen should have the notification bell
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);

    // ── 2. Navigate to GUADAGNI tab ──
    await tapBottomTab(tester, 'Guadagni');
    await waitFor(tester, find.text('SALDO DISPONIBILE'),
        timeout: const Duration(seconds: 10),
        description: 'Money screen should show balance');

    // ── 3. Navigate to MARKET tab ──
    await tapBottomTab(tester, 'Market');
    await waitFor(tester, find.text('COMING SOON'),
        timeout: const Duration(seconds: 5),
        description: 'Market screen should show COMING SOON');
    expect(find.text('Il marketplace dloop arriva presto!'), findsOneWidget);

    // ── 4. Navigate to PROFILO tab ──
    await tapBottomTab(tester, 'Profilo');
    await waitFor(tester, find.text('STATISTICHE LIFETIME'),
        timeout: const Duration(seconds: 10),
        description: 'Profile screen should show lifetime stats');
    expect(find.text('GAMIFICATION'), findsOneWidget);

    // ── 5. Navigate back to OGGI tab ──
    await tapBottomTab(tester, 'Oggi');
    await tester.pump(const Duration(seconds: 1));
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
  });
}
