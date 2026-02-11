import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/screens/auth/login_page.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  group('LoginPage', () {
    testWidgets('renders welcome text', (tester) async {
      await tester.pumpWidget(testScreen(const LoginPage()));

      expect(find.text('Bentornato!'), findsOneWidget);
      expect(find.text('Accedi per iniziare a consegnare'), findsOneWidget);
    });

    testWidgets('renders email field', (tester) async {
      await tester.pumpWidget(testScreen(const LoginPage()));

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('nome@esempio.com'), findsOneWidget);
    });

    testWidgets('renders password field', (tester) async {
      await tester.pumpWidget(testScreen(const LoginPage()));

      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('renders ACCEDI login button', (tester) async {
      await tester.pumpWidget(testScreen(const LoginPage()));

      expect(find.text('ACCEDI'), findsOneWidget);
    });

    testWidgets('renders Google sign-in button', (tester) async {
      await tester.pumpWidget(testScreen(const LoginPage()));

      expect(find.text('Accedi con Google'), findsOneWidget);
    });

    testWidgets('renders signup link', (tester) async {
      await tester.pumpWidget(testScreen(const LoginPage()));

      expect(find.text('Non hai un account? '), findsOneWidget);
      expect(find.text('Registrati'), findsOneWidget);
    });

    testWidgets('renders forgot password link', (tester) async {
      await tester.pumpWidget(testScreen(const LoginPage()));

      expect(find.text('Password dimenticata?'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty fields', (tester) async {
      await tester.pumpWidget(testScreen(const LoginPage()));

      await tester.tap(find.text('ACCEDI'));
      await tester.pumpAndSettle();

      expect(find.text('Inserisci la tua email'), findsOneWidget);
      expect(find.text('Inserisci la password'), findsOneWidget);
    });

    testWidgets('shows email validation error for invalid format', (tester) async {
      await tester.pumpWidget(testScreen(const LoginPage()));

      // Enter invalid email (no @)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'nome@esempio.com'),
        'invalidemail',
      );

      await tester.tap(find.text('ACCEDI'));
      await tester.pumpAndSettle();

      expect(find.text('Email non valida'), findsOneWidget);
    });

    testWidgets('renders oppure divider', (tester) async {
      await tester.pumpWidget(testScreen(const LoginPage()));

      expect(find.text('oppure'), findsOneWidget);
    });
  });
}
