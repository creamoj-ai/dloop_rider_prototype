import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fee_audit.dart';

class FeeAuditService {
  static final _client = Supabase.instance.client;
  static const _table = 'fee_audit';

  /// Get fee audit record for an order.
  static Future<FeeAudit?> getFeesForOrder(String orderId) async {
    final res = await _client
        .from(_table)
        .select()
        .eq('order_id', orderId)
        .maybeSingle();
    return res != null ? FeeAudit.fromJson(res) : null;
  }

  /// Get recent fee audit records for the current rider.
  static Future<List<FeeAudit>> getRecentFees({int limit = 20}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _client
        .from(_table)
        .select()
        .eq('rider_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);
    return (res as List).map((e) => FeeAudit.fromJson(e)).toList();
  }

  /// Stream fee audit records for the current rider.
  static Stream<List<FeeAudit>> streamFees() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const Stream.empty();
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('rider_id', uid)
        .map((rows) => rows.map((r) => FeeAudit.fromJson(r)).toList());
  }
}
