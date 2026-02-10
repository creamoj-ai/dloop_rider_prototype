import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/rider_repository.dart';

/// Rider profile + stats combined state
class RiderProfileState {
  final bool isLoading;
  final String? error;
  // Rider fields
  final String fullName;
  final String? avatarUrl;
  final String currentMode;
  final double rating;
  final int totalDeliveries;
  final double totalEarnings;
  // Stats fields
  final int currentLevel;
  final int currentXp;
  final int xpToNextLevel;
  final int currentDailyStreak;
  final int achievementsUnlocked;
  final int lifetimeOrders;
  final double lifetimeEarnings;
  final double avgRating;

  const RiderProfileState({
    this.isLoading = true,
    this.error,
    this.fullName = '',
    this.avatarUrl,
    this.currentMode = 'earn',
    this.rating = 0,
    this.totalDeliveries = 0,
    this.totalEarnings = 0,
    this.currentLevel = 1,
    this.currentXp = 0,
    this.xpToNextLevel = 100,
    this.currentDailyStreak = 0,
    this.achievementsUnlocked = 0,
    this.lifetimeOrders = 0,
    this.lifetimeEarnings = 0,
    this.avgRating = 0,
  });

  RiderProfileState copyWith({
    bool? isLoading,
    String? error,
    String? fullName,
    String? avatarUrl,
    String? currentMode,
    double? rating,
    int? totalDeliveries,
    double? totalEarnings,
    int? currentLevel,
    int? currentXp,
    int? xpToNextLevel,
    int? currentDailyStreak,
    int? achievementsUnlocked,
    int? lifetimeOrders,
    double? lifetimeEarnings,
    double? avgRating,
  }) {
    return RiderProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currentMode: currentMode ?? this.currentMode,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      currentLevel: currentLevel ?? this.currentLevel,
      currentXp: currentXp ?? this.currentXp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      currentDailyStreak: currentDailyStreak ?? this.currentDailyStreak,
      achievementsUnlocked: achievementsUnlocked ?? this.achievementsUnlocked,
      lifetimeOrders: lifetimeOrders ?? this.lifetimeOrders,
      lifetimeEarnings: lifetimeEarnings ?? this.lifetimeEarnings,
      avgRating: avgRating ?? this.avgRating,
    );
  }
}

class RiderProfileNotifier extends StateNotifier<RiderProfileState> {
  final RiderRepository _repo = RiderRepository();

  RiderProfileNotifier() : super(const RiderProfileState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _repo.getRiderWithStats();
      if (data == null) {
        state = state.copyWith(isLoading: false, error: 'Rider not found');
        return;
      }

      final stats = data['stats_data'] as Map<String, dynamic>?;

      state = RiderProfileState(
        isLoading: false,
        fullName: data['full_name'] ?? '',
        avatarUrl: data['avatar_url'],
        currentMode: data['current_mode'] ?? 'earn',
        rating: (data['rating'] as num?)?.toDouble() ?? 0,
        totalDeliveries: (data['total_deliveries'] as num?)?.toInt() ?? 0,
        totalEarnings: (data['total_earnings'] as num?)?.toDouble() ?? 0,
        currentLevel: (stats?['current_level'] as num?)?.toInt() ?? 1,
        currentXp: (stats?['current_xp'] as num?)?.toInt() ?? 0,
        xpToNextLevel: (stats?['xp_to_next_level'] as num?)?.toInt() ?? 100,
        currentDailyStreak: (stats?['current_daily_streak'] as num?)?.toInt() ?? 0,
        achievementsUnlocked: (stats?['achievements_unlocked'] as num?)?.toInt() ?? 0,
        lifetimeOrders: (stats?['lifetime_orders'] as num?)?.toInt() ?? 0,
        lifetimeEarnings: (stats?['lifetime_earnings'] as num?)?.toDouble() ?? 0,
        avgRating: (stats?['avg_rating'] as num?)?.toDouble() ?? 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final riderProfileProvider =
    StateNotifierProvider<RiderProfileNotifier, RiderProfileState>(
  (ref) => RiderProfileNotifier(),
);
