import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';

/// Streams rider GPS position to Supabase rider_locations table.
/// Started when session begins, stopped when session ends.
class LocationTrackingService {
  static final _client = Supabase.instance.client;
  static StreamSubscription<Position>? _positionSub;
  static Position? _lastSentPosition;
  static DateTime? _lastSentAt;
  static bool _isTracking = false;

  // Throttle constants
  static const _minDistanceMeters = 50.0;
  static const _minIntervalSeconds = 30;
  static const _staleThresholdSeconds = 120;

  /// Start tracking rider location. Call when session starts.
  static Future<void> startTracking() async {
    if (_isTracking) return;

    final ok = await LocationService.ensurePermission();
    if (!ok) return;

    _isTracking = true;
    _lastSentPosition = null;
    _lastSentAt = null;

    // Send initial position immediately
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _sendLocation(pos);
    } catch (_) {}

    // Start stream with balanced accuracy for battery efficiency
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 20,
      ),
    ).listen(
      (position) async {
        if (_shouldSend(position)) {
          await _sendLocation(position);
        }
      },
      onError: (_) {},
    );
  }

  /// Stop tracking. Call when session ends.
  static void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _isTracking = false;
    _lastSentPosition = null;
    _lastSentAt = null;
  }

  /// Whether we're currently tracking.
  static bool get isTracking => _isTracking;

  /// Determine whether to send this position based on throttle rules.
  static bool _shouldSend(Position pos) {
    // First position: always send
    if (_lastSentPosition == null || _lastSentAt == null) return true;

    final elapsed = DateTime.now().difference(_lastSentAt!).inSeconds;
    final distance = Geolocator.distanceBetween(
      _lastSentPosition!.latitude,
      _lastSentPosition!.longitude,
      pos.latitude,
      pos.longitude,
    );

    // Stale: force send every 2 minutes even if stationary
    if (elapsed >= _staleThresholdSeconds) return true;

    // Moved significantly: send if > 50m
    if (distance >= _minDistanceMeters) return true;

    // Minimum interval: send every 30s if moved > 10m
    if (elapsed >= _minIntervalSeconds && distance > 10) return true;

    return false;
  }

  /// Send position to Supabase via RPC.
  static Future<void> _sendLocation(Position pos) async {
    try {
      await _client.rpc('upsert_rider_location', params: {
        'p_lat': pos.latitude,
        'p_lng': pos.longitude,
        'p_heading': pos.heading,
        'p_speed': pos.speed,
        'p_accuracy': pos.accuracy,
      });
      _lastSentPosition = pos;
      _lastSentAt = DateTime.now();
    } catch (_) {
      // Non-blocking — next cycle will retry
    }
  }
}
