import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/providers/shift_timer_provider.dart';

void main() {
  group('ShiftTimerState', () {
    test('default values', () {
      const state = ShiftTimerState();

      expect(state.isRunning, false);
      expect(state.startedAt, isNull);
      expect(state.elapsedSeconds, 0);
      expect(state.sessionId, isNull);
    });

    group('formattedTime', () {
      test('formats 0 seconds as 00:00:00', () {
        const state = ShiftTimerState(elapsedSeconds: 0);
        expect(state.formattedTime, '00:00:00');
      });

      test('formats 65 seconds as 00:01:05', () {
        const state = ShiftTimerState(elapsedSeconds: 65);
        expect(state.formattedTime, '00:01:05');
      });

      test('formats 3661 seconds as 01:01:01', () {
        const state = ShiftTimerState(elapsedSeconds: 3661);
        expect(state.formattedTime, '01:01:01');
      });

      test('formats 7200 seconds as 02:00:00', () {
        const state = ShiftTimerState(elapsedSeconds: 7200);
        expect(state.formattedTime, '02:00:00');
      });

      test('formats 36000 seconds as 10:00:00', () {
        const state = ShiftTimerState(elapsedSeconds: 36000);
        expect(state.formattedTime, '10:00:00');
      });
    });

    group('copyWith', () {
      test('overwrites specified fields', () {
        const state = ShiftTimerState();
        final now = DateTime(2026, 2, 10, 8, 0);

        final updated = state.copyWith(
          isRunning: true,
          startedAt: now,
          elapsedSeconds: 120,
          sessionId: 'session-123',
        );

        expect(updated.isRunning, true);
        expect(updated.startedAt, now);
        expect(updated.elapsedSeconds, 120);
        expect(updated.sessionId, 'session-123');
      });

      test('preserves unspecified fields', () {
        final state = ShiftTimerState(
          isRunning: true,
          startedAt: DateTime(2026, 2, 10, 8),
          elapsedSeconds: 600,
          sessionId: 'sess-1',
        );

        final updated = state.copyWith(elapsedSeconds: 700);

        expect(updated.isRunning, true);
        expect(updated.startedAt, state.startedAt);
        expect(updated.elapsedSeconds, 700);
        expect(updated.sessionId, 'sess-1');
      });
    });
  });
}
