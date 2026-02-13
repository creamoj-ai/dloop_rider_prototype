import 'package:flutter_test/flutter_test.dart';

/// Tests for the LocationTrackingService shouldSend throttle logic.
/// The actual service uses Geolocator/Supabase so we test the pure logic here.

// Mirror of LocationTrackingService throttle constants
const minDistanceMeters = 50.0;
const minIntervalSeconds = 30;
const staleThresholdSeconds = 120;

/// Pure function mirror of LocationTrackingService._shouldSend
bool shouldSend({
  required bool hasLastPosition,
  required int elapsedSeconds,
  required double distanceMeters,
}) {
  // First position: always send
  if (!hasLastPosition) return true;

  // Stale: force send every 2 minutes even if stationary
  if (elapsedSeconds >= staleThresholdSeconds) return true;

  // Moved significantly: send if > 50m
  if (distanceMeters >= minDistanceMeters) return true;

  // Minimum interval: send every 30s if moved > 10m
  if (elapsedSeconds >= minIntervalSeconds && distanceMeters > 10) return true;

  return false;
}

void main() {
  group('shouldSend throttle logic', () {
    test('first position always sends', () {
      expect(
        shouldSend(hasLastPosition: false, elapsedSeconds: 0, distanceMeters: 0),
        true,
      );
    });

    test('sends when stale (>= 120s) even if stationary', () {
      expect(
        shouldSend(hasLastPosition: true, elapsedSeconds: 120, distanceMeters: 0),
        true,
      );
      expect(
        shouldSend(hasLastPosition: true, elapsedSeconds: 200, distanceMeters: 0),
        true,
      );
    });

    test('sends when moved >= 50m regardless of time', () {
      expect(
        shouldSend(hasLastPosition: true, elapsedSeconds: 5, distanceMeters: 50),
        true,
      );
      expect(
        shouldSend(hasLastPosition: true, elapsedSeconds: 1, distanceMeters: 100),
        true,
      );
    });

    test('sends at 30s interval if moved > 10m', () {
      expect(
        shouldSend(hasLastPosition: true, elapsedSeconds: 30, distanceMeters: 15),
        true,
      );
      expect(
        shouldSend(hasLastPosition: true, elapsedSeconds: 45, distanceMeters: 11),
        true,
      );
    });

    test('does NOT send at 30s if moved <= 10m', () {
      expect(
        shouldSend(hasLastPosition: true, elapsedSeconds: 30, distanceMeters: 10),
        false,
      );
      expect(
        shouldSend(hasLastPosition: true, elapsedSeconds: 30, distanceMeters: 5),
        false,
      );
    });

    test('does NOT send before interval if moved < 50m', () {
      expect(
        shouldSend(hasLastPosition: true, elapsedSeconds: 10, distanceMeters: 30),
        false,
      );
      expect(
        shouldSend(hasLastPosition: true, elapsedSeconds: 20, distanceMeters: 49),
        false,
      );
    });

    test('does NOT send if stationary and under stale threshold', () {
      expect(
        shouldSend(hasLastPosition: true, elapsedSeconds: 60, distanceMeters: 0),
        false,
      );
      expect(
        shouldSend(hasLastPosition: true, elapsedSeconds: 119, distanceMeters: 0),
        false,
      );
    });
  });
}
