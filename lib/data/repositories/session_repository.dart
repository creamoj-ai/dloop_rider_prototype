import 'package:supabase_flutter/supabase_flutter.dart';

class SessionRepository {
  final _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Fetch current active session
  Future<Map<String, dynamic>?> getActiveSession() async {
    if (_userId == null) return null;
    final res = await _client
        .from('sessions')
        .select()
        .eq('rider_id', _userId!)
        .eq('is_active', true)
        .maybeSingle();
    return res;
  }

  /// Start a new session — returns the session ID
  Future<String?> startSession() async {
    if (_userId == null) return null;

    // End any existing active session first
    await _client
        .from('sessions')
        .update({'is_active': false, 'end_time': DateTime.now().toIso8601String()})
        .eq('rider_id', _userId!)
        .eq('is_active', true);

    final res = await _client
        .from('sessions')
        .insert({
          'rider_id': _userId!,
          'start_time': DateTime.now().toIso8601String(),
          'is_active': true,
          'mode': 'earn',
          'session_earnings': 0,
          'orders_completed': 0,
          'distance_km': 0,
          'active_minutes': 0,
        })
        .select('id')
        .single();

    return res['id'] as String?;
  }

  /// End a session by ID
  Future<void> endSession(String sessionId, {int? durationMinutes, int? activeMinutes}) async {
    if (_userId == null) return;

    final updates = <String, dynamic>{
      'is_active': false,
      'end_time': DateTime.now().toIso8601String(),
    };
    if (durationMinutes != null) updates['duration_minutes'] = durationMinutes;
    if (activeMinutes != null) updates['active_minutes'] = activeMinutes;

    await _client
        .from('sessions')
        .update(updates)
        .eq('id', sessionId)
        .eq('rider_id', _userId!);
  }

  /// Update session metrics (orders, earnings, distance)
  Future<void> updateSessionMetrics(String sessionId, {
    int? ordersCompleted,
    double? sessionEarnings,
    double? distanceKm,
    int? activeMinutes,
  }) async {
    if (_userId == null) return;

    final updates = <String, dynamic>{};
    if (ordersCompleted != null) updates['orders_completed'] = ordersCompleted;
    if (sessionEarnings != null) updates['session_earnings'] = sessionEarnings;
    if (distanceKm != null) updates['distance_km'] = distanceKm;
    if (activeMinutes != null) updates['active_minutes'] = activeMinutes;

    if (updates.isEmpty) return;

    await _client
        .from('sessions')
        .update(updates)
        .eq('id', sessionId)
        .eq('rider_id', _userId!);
  }

}
