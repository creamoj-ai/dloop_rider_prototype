import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

/// Current position (one-shot)
final currentPositionProvider = FutureProvider<Position?>((ref) {
  return LocationService.getCurrentPosition();
});

/// Real-time position stream
final positionStreamProvider = StreamProvider<Position>((ref) {
  return LocationService.getPositionStream();
});
