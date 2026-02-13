import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/earning.dart';
import '../utils/logger.dart';
import '../utils/retry.dart';

class EarningsService {
  static final _client = Supabase.instance.client;

  static String? get _riderId => _client.auth.currentUser?.id;

  /// Fetch transactions for the current rider (with retry)
  static Future<List<Earning>> getEarnings({DateTime? since}) async {
    final riderId = _riderId;
    if (riderId == null) return [];

    try {
      return await retry(() async {
        var query = _client
            .from('transactions')
            .select()
            .eq('rider_id', riderId);

        if (since != null) {
          query = query.gte('processed_at', since.toIso8601String());
        }

        final response = await query.order('processed_at', ascending: false);

        return (response as List)
            .map((json) => Earning.fromJson(json))
            .toList();
      }, onRetry: (attempt, e) {
        dlog('⚡ EarningsService.getEarnings retry $attempt: $e');
      });
    } catch (e) {
      dlog('❌ EarningsService.getEarnings failed after retries: $e');
      return [];
    }
  }

  /// Create a new transaction record (with retry)
  static Future<void> createEarning(Earning earning) async {
    final riderId = _riderId;
    if (riderId == null) return;

    try {
      await retry(() async {
        await _client.from('transactions').insert({
          'rider_id': riderId,
          ...earning.toJson(),
        });
      }, onRetry: (attempt, e) {
        dlog('⚡ EarningsService.createEarning retry $attempt: $e');
      });
    } catch (e) {
      dlog('❌ EarningsService.createEarning failed after retries: $e');
    }
  }

  /// Subscribe to real-time transaction updates (with auto-reconnect)
  static Stream<List<Earning>> subscribeToEarnings() {
    final riderId = _riderId;
    if (riderId == null) {
      return Stream.value([]);
    }

    return retryStream(
      () => _client
          .from('transactions')
          .stream(primaryKey: ['id'])
          .eq('rider_id', riderId)
          .order('processed_at', ascending: false)
          .map((data) => data.map((json) => Earning.fromJson(json)).toList()),
      onReconnect: (attempt, e) {
        dlog('⚡ EarningsService.subscribeToEarnings reconnect $attempt: $e');
      },
    );
  }
}
