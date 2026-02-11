import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/retry.dart';

class MonthlyStats {
  final double totalEarnings;
  final int totalOrders;
  final double totalHoursOnline;
  final double totalDistanceKm;
  final int workDaysCount;
  final double bestDayEarnings;
  final String? bestDayDate;

  const MonthlyStats({
    this.totalEarnings = 0,
    this.totalOrders = 0,
    this.totalHoursOnline = 0,
    this.totalDistanceKm = 0,
    this.workDaysCount = 0,
    this.bestDayEarnings = 0,
    this.bestDayDate,
  });

  double get avgPerOrder => totalOrders > 0 ? totalEarnings / totalOrders : 0;
  double get avgPerHour => totalHoursOnline > 0 ? totalEarnings / totalHoursOnline : 0;
}

final monthlyStatsProvider = FutureProvider<MonthlyStats>((ref) async {
  final client = Supabase.instance.client;
  final riderId = client.auth.currentUser?.id;
  if (riderId == null) return const MonthlyStats();

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final nextMonthStart = DateTime(now.year, now.month + 1, 1);
  final monthStartIso = monthStart.toIso8601String();
  final nextMonthStartIso = nextMonthStart.toIso8601String();

  try {
    return await retry(() async {
      // 1. Transactions this month
      final transactions = await client
          .from('transactions')
          .select('amount, processed_at, status')
          .eq('rider_id', riderId)
          .eq('status', 'completed')
          .gte('processed_at', monthStartIso)
          .lt('processed_at', nextMonthStartIso)
          .order('processed_at', ascending: false);

      double totalEarnings = 0;
      double bestDayEarnings = 0;
      String? bestDayDate;
      final dayEarnings = <String, double>{};

      for (final t in transactions) {
        final amount = (t['amount'] as num?)?.toDouble() ?? 0;
        totalEarnings += amount;

        final processedAt = t['processed_at'] as String?;
        if (processedAt != null) {
          final day = processedAt.substring(0, 10); // YYYY-MM-DD
          dayEarnings[day] = (dayEarnings[day] ?? 0) + amount;
        }
      }

      for (final entry in dayEarnings.entries) {
        if (entry.value > bestDayEarnings) {
          bestDayEarnings = entry.value;
          bestDayDate = entry.key;
        }
      }

      // 2. Orders delivered this month
      final orders = await client
          .from('orders')
          .select('id, distance_km')
          .eq('rider_id', riderId)
          .eq('status', 'delivered')
          .gte('delivered_at', monthStartIso)
          .lt('delivered_at', nextMonthStartIso);

      int totalOrders = orders.length;
      double totalDistanceKm = 0;
      for (final o in orders) {
        totalDistanceKm += (o['distance_km'] as num?)?.toDouble() ?? 0;
      }

      // 3. Sessions this month
      final sessions = await client
          .from('sessions')
          .select('duration_minutes, start_time')
          .eq('rider_id', riderId)
          .gte('start_time', monthStartIso)
          .lt('start_time', nextMonthStartIso);

      double totalHours = 0;
      final workDays = <String>{};
      for (final s in sessions) {
        final minutes = (s['duration_minutes'] as num?)?.toDouble() ?? 0;
        totalHours += minutes / 60;

        final startTime = s['start_time'] as String?;
        if (startTime != null) {
          workDays.add(startTime.substring(0, 10));
        }
      }

      return MonthlyStats(
        totalEarnings: totalEarnings,
        totalOrders: totalOrders,
        totalHoursOnline: totalHours,
        totalDistanceKm: totalDistanceKm,
        workDaysCount: workDays.length,
        bestDayEarnings: bestDayEarnings,
        bestDayDate: bestDayDate,
      );
    }, onRetry: (attempt, e) {
      // ignore
    });
  } catch (e) {
    return const MonthlyStats();
  }
});
