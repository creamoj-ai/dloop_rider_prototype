import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/providers/rider_stats_provider.dart';

void main() {
  group('RiderStats', () {
    test('default values', () {
      const stats = RiderStats();

      expect(stats.lifetimeOrders, 0);
      expect(stats.lifetimeEarnings, 0);
      expect(stats.lifetimeDistanceKm, 0);
      expect(stats.lifetimeHoursOnline, 0);
      expect(stats.currentDailyStreak, 0);
      expect(stats.longestDailyStreak, 0);
      expect(stats.avgRating, 0);
      expect(stats.totalRatingsCount, 0);
      expect(stats.bestDayEarnings, 0);
      expect(stats.bestDayDate, isNull);
      expect(stats.achievementsUnlocked, 0);
      expect(stats.totalAchievementPoints, 0);
      expect(stats.currentLevel, 1);
      expect(stats.currentXp, 0);
      expect(stats.xpToNextLevel, 100);
    });

    group('fromJson', () {
      test('with complete data', () {
        final json = {
          'lifetime_orders': 256,
          'lifetime_earnings': 3450.75,
          'lifetime_distance_km': 1200.5,
          'lifetime_hours_online': 480.2,
          'current_daily_streak': 12,
          'longest_daily_streak': 25,
          'avg_rating': 4.85,
          'total_ratings_count': 198,
          'best_day_earnings': 125.50,
          'best_day_date': '2026-01-15',
          'achievements_unlocked': 8,
          'total_achievement_points': 350,
          'current_level': 7,
          'current_xp': 420,
          'xp_to_next_level': 500,
        };

        final stats = RiderStats.fromJson(json);

        expect(stats.lifetimeOrders, 256);
        expect(stats.lifetimeEarnings, 3450.75);
        expect(stats.lifetimeDistanceKm, 1200.5);
        expect(stats.lifetimeHoursOnline, 480.2);
        expect(stats.currentDailyStreak, 12);
        expect(stats.longestDailyStreak, 25);
        expect(stats.avgRating, 4.85);
        expect(stats.totalRatingsCount, 198);
        expect(stats.bestDayEarnings, 125.50);
        expect(stats.bestDayDate, '2026-01-15');
        expect(stats.achievementsUnlocked, 8);
        expect(stats.totalAchievementPoints, 350);
        expect(stats.currentLevel, 7);
        expect(stats.currentXp, 420);
        expect(stats.xpToNextLevel, 500);
      });

      test('with null values uses defaults', () {
        final stats = RiderStats.fromJson({});

        expect(stats.lifetimeOrders, 0);
        expect(stats.lifetimeEarnings, 0);
        expect(stats.currentDailyStreak, 0);
        expect(stats.avgRating, 0);
        expect(stats.bestDayDate, isNull);
        expect(stats.currentLevel, 1);
        expect(stats.currentXp, 0);
        expect(stats.xpToNextLevel, 100);
      });

      test('with values as strings (Supabase decimal)', () {
        final json = {
          'lifetime_orders': '256',
          'lifetime_earnings': '3450.75',
          'avg_rating': '4.85',
          'current_level': '7',
          'current_xp': '420',
          'xp_to_next_level': '500',
        };

        final stats = RiderStats.fromJson(json);

        expect(stats.lifetimeOrders, 256);
        expect(stats.lifetimeEarnings, 3450.75);
        expect(stats.avgRating, 4.85);
        expect(stats.currentLevel, 7);
        expect(stats.currentXp, 420);
        expect(stats.xpToNextLevel, 500);
      });
    });

    group('xpProgress', () {
      test('calculates correctly', () {
        final stats = RiderStats.fromJson({
          'current_xp': 250,
          'xp_to_next_level': 500,
        });

        expect(stats.xpProgress, 0.5);
      });

      test('returns 0 when xpToNextLevel is 0', () {
        final stats = RiderStats.fromJson({
          'current_xp': 100,
          'xp_to_next_level': 0,
        });

        expect(stats.xpProgress, 0);
      });

      test('returns 0 when xp is 0', () {
        final stats = RiderStats.fromJson({
          'current_xp': 0,
          'xp_to_next_level': 100,
        });

        expect(stats.xpProgress, 0);
      });

      test('can exceed 1.0 if xp > xpToNextLevel', () {
        final stats = RiderStats.fromJson({
          'current_xp': 600,
          'xp_to_next_level': 500,
        });

        expect(stats.xpProgress, 1.2);
      });
    });
  });
}
