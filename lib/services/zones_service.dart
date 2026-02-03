import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zone_data.dart';

class ZonesService {
  static final _client = Supabase.instance.client;

  /// Fetch all hot zones ordered by demand and earnings
  static Future<List<ZoneData>> getHotZones() async {
    try {
      final response = await _client
          .from('hot_zones')
          .select()
          .order('orders_per_hour', ascending: false);

      return (response as List)
          .map((json) => ZoneData.fromJson(json))
          .toList();
    } catch (e) {
      // Return mock data if Supabase fails or table doesn't exist
      return _mockZones;
    }
  }

  /// Fetch zones near a specific location
  static Future<List<ZoneData>> getZonesNearLocation(double lat, double lng, {double radiusKm = 10}) async {
    try {
      // For now, fetch all and filter client-side
      // In production, use PostGIS for geo queries
      final zones = await getHotZones();
      return zones.where((z) => z.distanceKm <= radiusKm).toList();
    } catch (e) {
      return _mockZones;
    }
  }

  /// Subscribe to real-time zone updates
  static Stream<List<ZoneData>> subscribeToZones() {
    return _client
        .from('hot_zones')
        .stream(primaryKey: ['id'])
        .order('orders_per_hour', ascending: false)
        .map((data) => data.map((json) => ZoneData.fromJson(json)).toList());
  }

  // Fallback mock data
  static final _mockZones = [
    ZoneData(
      id: '1',
      name: 'Milano Centro',
      demand: ZoneDemand.alta,
      ordersPerHour: 12,
      distanceKm: 0.5,
      earningMin: 16,
      earningMax: 20,
      latitude: 45.4642,
      longitude: 9.1900,
      updatedAt: DateTime.now(),
    ),
    ZoneData(
      id: '2',
      name: 'Navigli',
      demand: ZoneDemand.alta,
      ordersPerHour: 10,
      distanceKm: 1.2,
      earningMin: 14,
      earningMax: 18,
      latitude: 45.4531,
      longitude: 9.1747,
      updatedAt: DateTime.now(),
    ),
    ZoneData(
      id: '3',
      name: 'Porta Romana',
      demand: ZoneDemand.media,
      ordersPerHour: 8,
      distanceKm: 2.0,
      earningMin: 12,
      earningMax: 15,
      latitude: 45.4496,
      longitude: 9.2056,
      updatedAt: DateTime.now(),
    ),
    ZoneData(
      id: '4',
      name: 'Isola',
      demand: ZoneDemand.media,
      ordersPerHour: 6,
      distanceKm: 3.1,
      earningMin: 10,
      earningMax: 13,
      latitude: 45.4879,
      longitude: 9.1892,
      updatedAt: DateTime.now(),
    ),
    ZoneData(
      id: '5',
      name: 'Città Studi',
      demand: ZoneDemand.bassa,
      ordersPerHour: 4,
      distanceKm: 4.5,
      earningMin: 8,
      earningMax: 10,
      latitude: 45.4773,
      longitude: 9.2277,
      updatedAt: DateTime.now(),
    ),
  ];
}
