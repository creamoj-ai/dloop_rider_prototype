import 'dart:async';
import 'dart:math';

/// Retry a future-returning function with exponential backoff.
///
/// [fn] — the async operation to retry
/// [maxAttempts] — total attempts (default 3)
/// [initialDelay] — first retry delay (default 1s, doubles each time)
/// [onRetry] — optional callback on each retry (attempt number, error)
Future<T> retry<T>(
  Future<T> Function() fn, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
  void Function(int attempt, Object error)? onRetry,
}) async {
  var delay = initialDelay;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (e) {
      if (attempt == maxAttempts) rethrow;
      onRetry?.call(attempt, e);
      // Add jitter: delay ± 25%
      final jitter = delay.inMilliseconds * (0.75 + Random().nextDouble() * 0.5);
      await Future.delayed(Duration(milliseconds: jitter.round()));
      delay *= 2;
    }
  }
  // Unreachable, but satisfies the type system
  throw StateError('retry: exhausted all attempts');
}

/// Retry a stream subscription with auto-reconnect on error.
///
/// Returns a new stream that auto-reconnects up to [maxReconnects] times.
/// Each reconnect waits with exponential backoff starting at [initialDelay].
Stream<T> retryStream<T>(
  Stream<T> Function() streamFactory, {
  int maxReconnects = 5,
  Duration initialDelay = const Duration(seconds: 2),
  void Function(int attempt, Object error)? onReconnect,
}) async* {
  var reconnects = 0;
  var delay = initialDelay;

  while (reconnects <= maxReconnects) {
    try {
      await for (final event in streamFactory()) {
        reconnects = 0; // Reset on successful data
        delay = initialDelay;
        yield event;
      }
      // Stream ended normally
      return;
    } catch (e) {
      reconnects++;
      if (reconnects > maxReconnects) rethrow;
      onReconnect?.call(reconnects, e);
      final jitter = delay.inMilliseconds * (0.75 + Random().nextDouble() * 0.5);
      await Future.delayed(Duration(milliseconds: jitter.round()));
      delay *= 2;
    }
  }
}
