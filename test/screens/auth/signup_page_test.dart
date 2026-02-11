import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/screens/auth/signup_page.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  group('SignupPage', () {
    testWidgets('renders page title', (tester) async {
      await tester.pumpWidget(testScreen(const SignupPage()));

      expect(find.text('Crea il tuo account'), findsOneWidget);
      expect(find.text('Unisciti a migliaia di rider dloop'), findsOneWidget);
    });

    testWidgets('renders all four form fields', (tester) async {
      await tester.pumpWidget(testScreen(const SignupPage()));

      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Conferma password'), findsOneWidget);
    });

    testWidgets('renders REGISTRATI button', (tester) async {
      await tester.pumpWidget(testScreen(const SignupPage()));

      expect(find.text('REGISTRATI'), findsOneWidget);
    });

    testWidgets('renders terms and conditions', (tester) async {
      await tester.pumpWidget(testScreen(const SignupPage()));

      expect(
        find.text(
          'Registrandoti, accetti i nostri Termini di Servizio e la Privacy Policy',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders login link', (tester) async {
      await tester.pumpWidget(testScreen(const SignupPage()));

      expect(find.text('Hai già un account? '), findsOneWidget);
      expect(find.text('Accedi'), findsOneWidget);
    });

    testWidgets('renders person_add icon', (tester) async {
      await tester.pumpWidget(testScreen(const SignupPage()));

      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(testScreen(const SignupPage()));

      // Scroll down to make REGISTRATI visible
      await tester.scrollUntilVisible(
        find.text('REGISTRATI'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('REGISTRATI'));
      await tester.pumpAndSettle();

      expect(find.text('Inserisci il tuo nome'), findsOneWidget);
      expect(find.text('Inserisci la tua email'), findsOneWidget);
    });

    testWidgets('shows password mismatch error', (tester) async {
      await tester.pumpWidget(testScreen(const SignupPage()));

      // Fill all fields but with different passwords
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mario Rossi'),
        'Mario Rossi',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'nome@esempio.com'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Minimo 6 caratteri'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ripeti la password'),
        'differentpassword',
      );

      // Scroll down to make REGISTRATI visible
      await tester.scrollUntilVisible(
        find.text('REGISTRATI'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('REGISTRATI'));
      await tester.pumpAndSettle();

      expect(find.text('Le password non coincidono'), findsOneWidget);
    });
  });
}
