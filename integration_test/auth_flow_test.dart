/// Integration Test 1: Auth Flow (unauthenticated)
///
/// Tests splash → login → signup navigation without needing valid credentials.
/// Run: flutter test integration_test/auth_flow_test.dart -d ZPPBN795OFDMON9L
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Auth Flow: splash → login → form validation → signup',
      (tester) async {
    // ── Launch app (signs out, waits for login page) ──
    await launchApp(tester);

    // ── 1. Verify login page elements ──
    expect(find.text('Bentornato!'), findsOneWidget);
    expect(find.text('Accedi per iniziare a consegnare'), findsOneWidget);
    expect(find.text('ACCEDI'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Google Sign-In button
    expect(find.text('Accedi con Google'), findsOneWidget);

    // Divider
    expect(find.text('oppure'), findsOneWidget);

    // Signup link
    expect(find.text('Non hai un account? '), findsOneWidget);
    expect(find.text('Registrati'), findsOneWidget);

    // Forgot password
    expect(find.text('Password dimenticata?'), findsOneWidget);

    // ── 2. Test form validation on empty submit ──
    await tester.tap(find.text('ACCEDI'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Inserisci la tua email'), findsOneWidget);
    expect(find.text('Inserisci la password'), findsOneWidget);

    // ── 3. Navigate to signup page ──
    // After validation errors, 'Registrati' may be off-screen — scroll to it
    await tester.ensureVisible(find.text('Registrati'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Registrati'));
    await waitFor(tester, find.text('Crea il tuo account'),
        timeout: const Duration(seconds: 5),
        description: 'Signup page should appear');

    // Verify signup form elements
    expect(find.text('Crea il tuo account'), findsOneWidget);
    expect(find.text('Nome completo'), findsOneWidget);
    expect(find.text('Conferma password'), findsOneWidget);

    // ── 4. Test signup form validation on empty submit ──
    await scrollToFind(tester, find.text('REGISTRATI'));
    await tester.tap(find.text('REGISTRATI'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Inserisci il tuo nome'), findsOneWidget);
    expect(find.text('Inserisci la tua email'), findsOneWidget);
  });
}
