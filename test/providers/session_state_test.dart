import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/providers/session_provider.dart';

void main() {
  group('ActiveSessionState', () {
    test('default values', () {
      const state = ActiveSessionState();

      expect(state.isLoading, true);
      expect(state.error, isNull);
      expect(state.hasActiveSession, false);
      expect(state.mode, 'earn');
      expect(state.zoneName, '');
      expect(state.zoneCity, '');
      expect(state.sessionEarnings, 0);
      expect(state.ordersCompleted, 0);
      expect(state.distanceKm, 0);
      expect(state.activeMinutes, 0);
      expect(state.startTime, isNull);
    });

    group('copyWith', () {
      test('overwrites specified fields', () {
        const state = ActiveSessionState();

        final updated = state.copyWith(
          isLoading: false,
          hasActiveSession: true,
          mode: 'grow',
          zoneName: 'Centro',
          zoneCity: 'Napoli',
          sessionEarnings: 45.50,
          ordersCompleted: 5,
          distanceKm: 12.3,
          activeMinutes: 180,
          startTime: DateTime(2026, 2, 10, 8),
        );

        expect(updated.isLoading, false);
        expect(updated.hasActiveSession, true);
        expect(updated.mode, 'grow');
        expect(updated.zoneName, 'Centro');
        expect(updated.zoneCity, 'Napoli');
        expect(updated.sessionEarnings, 45.50);
        expect(updated.ordersCompleted, 5);
        expect(updated.distanceKm, 12.3);
        expect(updated.activeMinutes, 180);
        expect(updated.startTime, DateTime(2026, 2, 10, 8));
      });

      test('without parameters keeps original values', () {
        final state = ActiveSessionState(
          isLoading: false,
          hasActiveSession: true,
          mode: 'earn',
          zoneName: 'Vomero',
          sessionEarnings: 30.0,
          ordersCompleted: 3,
        );

        final copy = state.copyWith();

        expect(copy.isLoading, false);
        expect(copy.hasActiveSession, true);
        expect(copy.zoneName, 'Vomero');
        expect(copy.sessionEarnings, 30.0);
        expect(copy.ordersCompleted, 3);
      });

      test('error resets to null via copyWith', () {
        final state = ActiveSessionState(
          error: 'Connection failed',
        );
        expect(state.error, 'Connection failed');

        // copyWith uses error directly (not ?? fallback)
        final cleared = state.copyWith();
        expect(cleared.error, isNull);
      });
    });

    test('session duration can be derived from activeMinutes', () {
      const state = ActiveSessionState(
        activeMinutes: 135,
      );

      final hours = state.activeMinutes ~/ 60;
      final minutes = state.activeMinutes % 60;
      expect(hours, 2);
      expect(minutes, 15);
    });
  });
}
