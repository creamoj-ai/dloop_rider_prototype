import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersRepository {
  final _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Fetch today's orders
  Future<List<Map<String, dynamic>>> getTodayOrders() async {
    if (_userId == null) return [];
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final res = await _client
        .from('orders')
        .select()
        .eq('rider_id', _userId!)
        .gte('created_at', '${today}T00:00:00')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Fetch active/in-progress orders
  Future<List<Map<String, dynamic>>> getActiveOrders() async {
    if (_userId == null) return [];
    final res = await _client
        .from('orders')
        .select()
        .eq('rider_id', _userId!)
        .inFilter('status', ['pending', 'accepted', 'picked_up', 'delivering'])
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }
}
