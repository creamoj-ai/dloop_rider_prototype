import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/zone_data.dart';
import '../services/zones_service.dart';

/// Real-time stream of hot zones from Supabase
final zonesStreamProvider = StreamProvider<List<ZoneData>>((ref) {
  return ZonesService.subscribeToZones();
});

/// One-shot fetch of hot zones (fallback)
final zonesProvider = FutureProvider<List<ZoneData>>((ref) {
  return ZonesService.getHotZones();
});
