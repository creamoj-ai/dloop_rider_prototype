import 'package:supabase_flutter/supabase_flutter.dart';

class EarningsRepository {
  final _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Fetch today's earnings summary
  Future<Map<String, dynamic>?> getTodayEarnings() async {
    if (_userId == null) return null;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final res = await _client
        .from('earnings_daily')
        .select()
        .eq('rider_id', _userId!)
        .eq('date', today)
        .maybeSingle();
    return res;
  }

  /// Fetch current month earnings
  Future<Map<String, dynamic>?> getMonthlyEarnings() async {
    if (_userId == null) return null;
    final now = DateTime.now();
    final res = await _client
        .from('earnings_monthly')
        .select()
        .eq('rider_id', _userId!)
        .eq('year', now.year)
        .eq('month', now.month)
        .maybeSingle();
    return res;
  }

  /// Fetch recent transactions
  Future<List<Map<String, dynamic>>> getRecentTransactions({int limit = 10}) async {
    if (_userId == null) return [];
    final res = await _client
        .from('transactions')
        .select()
        .eq('rider_id', _userId!)
        .order('processed_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Calculate available balance from completed transactions
  Future<double> getBalance() async {
    if (_userId == null) return 0;
    final res = await _client
        .from('transactions')
        .select('amount, type, status')
        .eq('rider_id', _userId!)
        .eq('status', 'completed');
    final list = List<Map<String, dynamic>>.from(res);
    double balance = 0;
    for (final tx in list) {
      final amount = (tx['amount'] as num).toDouble();
      final type = tx['type'] as String;
      if (type == 'withdrawal' || type == 'penalty' || type == 'subscription_fee') {
        balance -= amount;
      } else {
        balance += amount;
      }
    }
    return balance;
  }

  /// Fetch pending transactions total
  Future<double> getPendingBalance() async {
    if (_userId == null) return 0;
    final res = await _client
        .from('transactions')
        .select('amount')
        .eq('rider_id', _userId!)
        .eq('status', 'pending');
    final list = List<Map<String, dynamic>>.from(res);
    double total = 0;
    for (final tx in list) {
      total += (tx['amount'] as num).toDouble();
    }
    return total;
  }
}
