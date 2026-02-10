import 'package:supabase_flutter/supabase_flutter.dart';

class SessionRepository {
  final _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Fetch current active session
  Future<Map<String, dynamic>?> getActiveSession() async {
    if (_userId == null) return null;
    final res = await _client
        .from('sessions')
        .select('*, zones!start_zone_id(name, city)')
        .eq('rider_id', _userId!)
        .eq('is_active', true)
        .maybeSingle();
    return res;
  }

  /// Fetch zone metrics live for Napoli
  Future<List<Map<String, dynamic>>> getZoneMetrics() async {
    final res = await _client
        .from('zone_metrics_live')
        .select('*, zones(name, city, center_lat, center_lng, demand_score)')
        .order('heatmap_score', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(res);
  }
}
