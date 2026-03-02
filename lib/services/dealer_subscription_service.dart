import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dealer_subscription.dart';

class DealerSubscriptionService {
  static final _client = Supabase.instance.client;
  static const _table = 'dealer_subscriptions';

  /// Get active subscription for a dealer contact.
  static Future<DealerSubscription?> getSubscription(
      String dealerContactId) async {
    final res = await _client
        .from(_table)
        .select()
        .eq('dealer_contact_id', dealerContactId)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return res != null ? DealerSubscription.fromJson(res) : null;
  }

  /// Get all active subscriptions for the current rider's dealers.
  static Future<List<DealerSubscription>> getActiveSubscriptions() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _client
        .from(_table)
        .select()
        .eq('rider_id', uid)
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return (res as List).map((e) => DealerSubscription.fromJson(e)).toList();
  }

  /// Stream active subscriptions for the current rider.
  static Stream<List<DealerSubscription>> streamSubscriptions() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const Stream.empty();
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('rider_id', uid)
        .map((rows) => rows
            .where((r) => r['is_active'] == true)
            .map((r) => DealerSubscription.fromJson(r))
            .toList());
  }
}
