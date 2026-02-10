import 'package:supabase_flutter/supabase_flutter.dart';

class RiderRepository {
  final _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Fetch rider profile
  Future<Map<String, dynamic>?> getRiderProfile() async {
    if (_userId == null) return null;
    final res = await _client
        .from('riders')
        .select()
        .eq('id', _userId!)
        .maybeSingle();
    return res;
  }

  /// Fetch rider stats (gamification)
  Future<Map<String, dynamic>?> getRiderStats() async {
    if (_userId == null) return null;
    final res = await _client
        .from('rider_stats')
        .select()
        .eq('rider_id', _userId!)
        .maybeSingle();
    return res;
  }

  /// Fetch rider profile + stats combined
  Future<Map<String, dynamic>?> getRiderWithStats() async {
    final profile = await getRiderProfile();
    if (profile == null) return null;

    final stats = await getRiderStats();
    return {
      ...profile,
      'stats_data': stats,
    };
  }
}
