import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/screens/today/widgets/countdown_timer.dart';

void main() {
  group('CountdownTimer', () {
    testWidgets('shows seconds remaining', (tester) async {
      final expiresAt = DateTime.now().add(const Duration(seconds: 45));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownTimer(expiresAt: expiresAt),
          ),
        ),
      );

      // Should show something around 44-45s
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, matches(RegExp(r'^\d+s$')));
    });

    testWidgets('uses orange color when > 15 seconds', (tester) async {
      final expiresAt = DateTime.now().add(const Duration(seconds: 30));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownTimer(expiresAt: expiresAt),
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, const Color(0xFFFF9800));
    });

    testWidgets('uses red color when < 15 seconds', (tester) async {
      final expiresAt = DateTime.now().add(const Duration(seconds: 10));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownTimer(expiresAt: expiresAt),
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, const Color(0xFFEF4444));
    });

    testWidgets('calls onExpired when timer is already expired', (tester) async {
      bool expired = false;
      // Set expiry 1 second in the past so onExpired fires on first tick
      final expiresAt = DateTime.now().subtract(const Duration(seconds: 1));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownTimer(
              expiresAt: expiresAt,
              onExpired: () => expired = true,
            ),
          ),
        ),
      );

      // First periodic tick should fire onExpired since seconds <= 0
      await tester.pump(const Duration(seconds: 1));

      expect(expired, true);
    });

    testWidgets('shows 0s when already expired', (tester) async {
      final expiresAt = DateTime.now().subtract(const Duration(seconds: 5));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownTimer(expiresAt: expiresAt),
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, '0s');
    });
  });
}
