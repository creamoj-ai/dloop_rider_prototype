import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dloop_rider_prototype/firebase_options.dart';
import 'package:dloop_rider_prototype/config/supabase_config.dart';
import 'package:dloop_rider_prototype/main.dart' show DloopRiderApp;

/// Test credentials — add TEST_EMAIL and TEST_PASSWORD to your .env file
String get testEmail => dotenv.env['TEST_EMAIL'] ?? 'creamoj@gmail.com';
String get testPassword => dotenv.env['TEST_PASSWORD'] ?? '';

bool _initialized = false;

/// Initialize dotenv, Firebase, and Supabase (safe to call multiple times).
/// Skips PushNotificationService.initialize() to avoid permission dialogs.
Future<void> _initServices() async {
  if (_initialized) return;

  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('it_IT', null);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Already initialized
  }

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (_) {
    // Already initialized
  }

  _initialized = true;
}

/// Launch the app with no active session.
/// Signs out any existing session so splash navigates to /login.
/// Skips PushNotificationService to avoid system permission dialogs.
Future<void> launchApp(WidgetTester tester) async {
  await _initServices();

  // Sign out to force splash → login (no biometric dialog)
  try {
    await Supabase.instance.client.auth.signOut();
  } catch (_) {}

  // Launch app (same widget tree as real app, without push init)
  runApp(const ProviderScope(child: DloopRiderApp()));

  // Pump initial frame
  await tester.pump();

  // Wait for splash's 2-second delay + auth check + navigation
  // Use real-time waiting since integration tests use real async
  await waitFor(tester, find.text('Bentornato!'),
      timeout: const Duration(seconds: 15),
      description: 'Login page should appear after splash');
}

/// Wait for a widget to appear, pumping frames until found or timeout.
/// Works with screens that have ongoing animations (unlike pumpAndSettle).
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
  String? description,
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  // Final assertion
  expect(finder, findsWidgets, reason: description ?? 'Timed out waiting for widget');
}

/// Wait for a widget to disappear.
Future<void> waitForGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isEmpty) return;
  }
  expect(finder, findsNothing, reason: 'Widget did not disappear');
}

/// Log in with test credentials via the UI.
/// Assumes the login page is currently visible.
Future<void> loginWithCredentials(WidgetTester tester) async {
  final email = testEmail;
  final password = testPassword;

  if (password.isEmpty) {
    fail('TEST_PASSWORD not set in .env — add TEST_EMAIL and TEST_PASSWORD');
  }

  // Enter email
  final emailField = find.widgetWithText(TextFormField, 'nome@esempio.com');
  await tester.tap(emailField);
  await tester.enterText(emailField, email);

  // Enter password
  final passwordField = find.widgetWithText(TextFormField, '••••••••');
  await tester.tap(passwordField);
  await tester.enterText(passwordField, password);

  // Hide keyboard and wait
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump(const Duration(seconds: 1));

  // Ensure ACCEDI is visible (keyboard may obscure it) then tap
  await tester.ensureVisible(find.text('ACCEDI'));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text('ACCEDI'));

  // Wait for network + navigation to Today screen
  await waitFor(tester, find.text('Oggi'),
      timeout: const Duration(seconds: 15),
      description: 'Should navigate to Today screen after login');
}

/// Navigate to a bottom tab by tapping its icon (avoids ambiguous text matches).
Future<void> tapBottomTab(WidgetTester tester, String label) async {
  const tabIcons = {
    'Oggi': Icons.bolt,
    'Guadagni': Icons.wallet,
    'Market': Icons.shopping_cart,
    'Profilo': Icons.person,
  };
  final icon = tabIcons[label];
  if (icon != null) {
    await tester.tap(find.byIcon(icon).last);
  } else {
    await tester.tap(find.text(label).last);
  }
  await tester.pump(const Duration(milliseconds: 500));
}

/// Tap the back button in the AppBar.
Future<void> tapBack(WidgetTester tester) async {
  final backButton = find.byType(BackButton);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton);
  } else {
    await tester.tap(find.byIcon(Icons.arrow_back));
  }
  await tester.pump(const Duration(milliseconds: 500));
}

/// Scroll to make a widget visible in its enclosing Scrollable.
/// Uses ensureVisible which is more reliable than manual drag.
Future<void> scrollToFind(
  WidgetTester tester,
  Finder finder,
) async {
  // First wait for the widget to exist in the tree
  final end = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(end)) {
    if (finder.evaluate().isNotEmpty) break;
    await tester.pump(const Duration(milliseconds: 200));
  }
  if (finder.evaluate().isEmpty) return; // Widget not in tree at all

  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
}
