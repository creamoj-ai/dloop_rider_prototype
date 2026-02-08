import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/earning.dart';

class EarningsService {
  static final _client = Supabase.instance.client;

  static String? get _riderId => _client.auth.currentUser?.id;

  /// Fetch earnings for the current rider
  static Future<List<Earning>> getEarnings({DateTime? since}) async {
    try {
      final riderId = _riderId;
      if (riderId == null) return [];

      var query = _client
          .from('earnings')
          .select()
          .eq('rider_id', riderId);

      if (since != null) {
        query = query.gte('date_time', since.toIso8601String());
      }

      final response = await query.order('date_time', ascending: false);

      return (response as List)
          .map((json) => Earning.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Create a new earning record
  static Future<void> createEarning(Earning earning) async {
    try {
      final riderId = _riderId;
      if (riderId == null) return;

      await _client.from('earnings').insert({
        'rider_id': riderId,
        ...earning.toJson(),
      });
    } catch (e) {
      // Silently fail — local state is source of truth
    }
  }

  /// Subscribe to real-time earnings updates
  static Stream<List<Earning>> subscribeToEarnings() {
    final riderId = _riderId;
    if (riderId == null) {
      return Stream.value([]);
    }

    return _client
        .from('earnings')
        .stream(primaryKey: ['id'])
        .eq('rider_id', riderId)
        .order('date_time', ascending: false)
        .map((data) => data.map((json) => Earning.fromJson(json)).toList());
  }
}
