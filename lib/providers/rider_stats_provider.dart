import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../utils/retry.dart';

/// Rider stats from the rider_stats table (lifetime + gamification)
class RiderStats {
  final int lifetimeOrders;
  final double lifetimeEarnings;
  final double lifetimeDistanceKm;
  final double lifetimeHoursOnline;
  final int currentDailyStreak;
  final int longestDailyStreak;
  final double avgRating;
  final int totalRatingsCount;
  final double bestDayEarnings;
  final String? bestDayDate;
  final int achievementsUnlocked;
  final int totalAchievementPoints;
  final int currentLevel;
  final int currentXp;
  final int xpToNextLevel;

  const RiderStats({
    this.lifetimeOrders = 0,
    this.lifetimeEarnings = 0,
    this.lifetimeDistanceKm = 0,
    this.lifetimeHoursOnline = 0,
    this.currentDailyStreak = 0,
    this.longestDailyStreak = 0,
    this.avgRating = 0,
    this.totalRatingsCount = 0,
    this.bestDayEarnings = 0,
    this.bestDayDate,
    this.achievementsUnlocked = 0,
    this.totalAchievementPoints = 0,
    this.currentLevel = 1,
    this.currentXp = 0,
    this.xpToNextLevel = 100,
  });

  double get xpProgress =>
      xpToNextLevel > 0 ? currentXp / xpToNextLevel : 0;

  factory RiderStats.fromJson(Map<String, dynamic> json) {
    double _num(dynamic v, [double fallback = 0]) =>
        double.tryParse(v?.toString() ?? '') ?? fallback;
    int _int(dynamic v, [int fallback = 0]) =>
        int.tryParse(v?.toString() ?? '') ?? fallback;

    return RiderStats(
      lifetimeOrders: _int(json['lifetime_orders']),
      lifetimeEarnings: _num(json['lifetime_earnings']),
      lifetimeDistanceKm: _num(json['lifetime_distance_km']),
      lifetimeHoursOnline: _num(json['lifetime_hours_online']),
      currentDailyStreak: _int(json['current_daily_streak']),
      longestDailyStreak: _int(json['longest_daily_streak']),
      avgRating: _num(json['avg_rating']),
      totalRatingsCount: _int(json['total_ratings_count']),
      bestDayEarnings: _num(json['best_day_earnings']),
      bestDayDate: json['best_day_date'] as String?,
      achievementsUnlocked: _int(json['achievements_unlocked']),
      totalAchievementPoints: _int(json['total_achievement_points']),
      currentLevel: _int(json['current_level'], 1),
      currentXp: _int(json['current_xp']),
      xpToNextLevel: _int(json['xp_to_next_level'], 100),
    );
  }
}

/// Fetches rider_stats for the current user
final riderStatsProvider = FutureProvider<RiderStats>((ref) async {
  final client = Supabase.instance.client;
  final riderId = client.auth.currentUser?.id;
  if (riderId == null) return const RiderStats();

  try {
    return await retry(() async {
      final response = await client
          .from('rider_stats')
          .select()
          .eq('rider_id', riderId)
          .single();

      return RiderStats.fromJson(response);
    }, onRetry: (attempt, e) {
      dlog('⚡ riderStatsProvider retry $attempt: $e');
    });
  } catch (e) {
    dlog('❌ riderStatsProvider failed: $e');
    return const RiderStats();
  }
});
