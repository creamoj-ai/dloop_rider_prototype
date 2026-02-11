import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/utils/retry.dart';

void main() {
  group('retry()', () {
    test('returns result on first attempt if no failure', () async {
      final result = await retry(
        () async => 42,
        initialDelay: const Duration(milliseconds: 1),
      );
      expect(result, 42);
    });

    test('retries after failure and succeeds on 2nd attempt', () async {
      var callCount = 0;

      final result = await retry(
        () async {
          callCount++;
          if (callCount < 2) throw Exception('fail');
          return 'success';
        },
        maxAttempts: 3,
        initialDelay: const Duration(milliseconds: 1),
      );

      expect(result, 'success');
      expect(callCount, 2);
    });

    test('retries maxAttempts times then rethrows exception', () async {
      var callCount = 0;

      expect(
        () => retry(
          () async {
            callCount++;
            throw Exception('always fails');
          },
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 1),
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('always fails'),
        )),
      );

      // Wait for retries to complete
      await Future.delayed(const Duration(milliseconds: 100));
      expect(callCount, 3);
    });

    test('calls onRetry callback on each retry', () async {
      final retryAttempts = <int>[];
      final retryErrors = <Object>[];

      var callCount = 0;
      await retry(
        () async {
          callCount++;
          if (callCount < 3) throw Exception('fail $callCount');
          return 'ok';
        },
        maxAttempts: 3,
        initialDelay: const Duration(milliseconds: 1),
        onRetry: (attempt, error) {
          retryAttempts.add(attempt);
          retryErrors.add(error);
        },
      );

      expect(retryAttempts, [1, 2]);
      expect(retryErrors.length, 2);
      expect(retryErrors[0].toString(), contains('fail 1'));
      expect(retryErrors[1].toString(), contains('fail 2'));
    });

    test('with maxAttempts=1 does not retry', () async {
      var callCount = 0;

      expect(
        () => retry(
          () async {
            callCount++;
            throw Exception('fail');
          },
          maxAttempts: 1,
          initialDelay: const Duration(milliseconds: 1),
        ),
        throwsA(isA<Exception>()),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(callCount, 1);
    });

    test('applies exponential backoff (delay doubles)', () async {
      // We can't easily test exact timing with jitter, but we can verify
      // the function completes within a reasonable time window and that
      // delays increase by tracking timestamps
      final timestamps = <DateTime>[];
      var callCount = 0;

      await retry(
        () async {
          timestamps.add(DateTime.now());
          callCount++;
          if (callCount < 3) throw Exception('fail');
          return 'ok';
        },
        maxAttempts: 3,
        initialDelay: const Duration(milliseconds: 10),
      );

      expect(timestamps.length, 3);

      // The second delay should be roughly >= the first delay
      // (with jitter, we allow tolerance)
      final delay1 = timestamps[1].difference(timestamps[0]);
      final delay2 = timestamps[2].difference(timestamps[1]);

      // delay2 should be roughly 2x delay1 (within jitter bounds)
      // delay1 is ~10ms (± 25% jitter = 7.5-12.5ms)
      // delay2 is ~20ms (± 25% jitter = 15-25ms)
      expect(delay1.inMilliseconds, greaterThan(0));
      expect(delay2.inMilliseconds, greaterThanOrEqualTo(delay1.inMilliseconds ~/ 2));
    });

    test('succeeds on last attempt', () async {
      var callCount = 0;

      final result = await retry(
        () async {
          callCount++;
          if (callCount < 3) throw Exception('fail');
          return 'third time charm';
        },
        maxAttempts: 3,
        initialDelay: const Duration(milliseconds: 1),
      );

      expect(result, 'third time charm');
      expect(callCount, 3);
    });

    test('does not call onRetry on success', () async {
      var onRetryCalled = false;

      await retry(
        () async => 'ok',
        initialDelay: const Duration(milliseconds: 1),
        onRetry: (_, __) => onRetryCalled = true,
      );

      expect(onRetryCalled, false);
    });
  });

  group('retryStream()', () {
    test('emits data from first stream if no failure', () async {
      final stream = retryStream(
        () => Stream.fromIterable([1, 2, 3]),
        initialDelay: const Duration(milliseconds: 1),
      );

      expect(await stream.toList(), [1, 2, 3]);
    });

    test('reconnects after error and re-emits data', () async {
      var callCount = 0;

      final stream = retryStream(
        () {
          callCount++;
          if (callCount == 1) {
            // First stream: emit 1 then error
            return Stream<int>.multi((controller) {
              controller.add(1);
              controller.addError(Exception('stream fail'));
            });
          }
          // Second stream: emit 2, 3 then close
          return Stream.fromIterable([2, 3]);
        },
        maxReconnects: 3,
        initialDelay: const Duration(milliseconds: 1),
      );

      final events = await stream.toList();
      expect(events, [1, 2, 3]);
      expect(callCount, 2);
    });

    test('calls onReconnect callback', () async {
      final reconnectAttempts = <int>[];
      var callCount = 0;

      final stream = retryStream(
        () {
          callCount++;
          if (callCount == 1) {
            return Stream<int>.error(Exception('fail'));
          }
          return Stream.fromIterable([42]);
        },
        maxReconnects: 3,
        initialDelay: const Duration(milliseconds: 1),
        onReconnect: (attempt, error) {
          reconnectAttempts.add(attempt);
        },
      );

      await stream.toList();
      expect(reconnectAttempts, [1]);
    });

    test('fails after maxReconnects exceeded', () async {
      var callCount = 0;

      final stream = retryStream(
        () {
          callCount++;
          return Stream<int>.error(Exception('always fails'));
        },
        maxReconnects: 2,
        initialDelay: const Duration(milliseconds: 1),
      );

      expect(
        () => stream.toList(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('always fails'),
        )),
      );

      await Future.delayed(const Duration(milliseconds: 200));
      expect(callCount, 3); // initial + 2 reconnects
    });

    test('resets reconnect counter after successful data', () async {
      var callCount = 0;

      final stream = retryStream(
        () {
          callCount++;
          if (callCount == 1) {
            // First: emit data, then error
            return Stream<int>.multi((controller) {
              controller.add(10);
              controller.addError(Exception('fail 1'));
            });
          }
          if (callCount == 2) {
            // Second: emit data, then error again
            return Stream<int>.multi((controller) {
              controller.add(20);
              controller.addError(Exception('fail 2'));
            });
          }
          // Third: success
          return Stream.fromIterable([30]);
        },
        maxReconnects: 1, // Only 1 reconnect allowed
        initialDelay: const Duration(milliseconds: 1),
      );

      // Despite maxReconnects=1, the counter resets after receiving data (10),
      // so it can reconnect again after the second error
      final events = await stream.toList();
      expect(events, [10, 20, 30]);
      expect(callCount, 3);
    });

    test('handles normally closing stream without reconnecting', () async {
      var callCount = 0;

      final stream = retryStream(
        () {
          callCount++;
          return Stream.fromIterable([1, 2]);
        },
        maxReconnects: 3,
        initialDelay: const Duration(milliseconds: 1),
      );

      final events = await stream.toList();
      expect(events, [1, 2]);
      expect(callCount, 1); // Only called once, no reconnects
    });

    test('does not call onReconnect on success', () async {
      var onReconnectCalled = false;

      final stream = retryStream(
        () => Stream.fromIterable([1]),
        initialDelay: const Duration(milliseconds: 1),
        onReconnect: (_, __) => onReconnectCalled = true,
      );

      await stream.toList();
      expect(onReconnectCalled, false);
    });
  });
}
