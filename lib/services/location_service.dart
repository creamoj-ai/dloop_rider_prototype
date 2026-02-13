import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Request permissions and check if location is available.
  /// Returns true if we can use location.
  static Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Get current position (requests permission first).
  static Future<Position?> getCurrentPosition() async {
    final ok = await ensurePermission();
    if (!ok) return null;

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Stream of position updates (requests permission first).
  static Stream<Position> getPositionStream() async* {
    final ok = await ensurePermission();
    if (!ok) return;

    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  /// Battery-efficient stream for background tracking.
  /// Uses balanced accuracy and coarser distance filter.
  static Stream<Position> getPositionStreamBalanced() async* {
    final ok = await ensurePermission();
    if (!ok) return;

    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 20,
      ),
    );
  }
}
