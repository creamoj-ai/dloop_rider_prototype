import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/earnings_repository.dart';

/// State for today's earnings from Supabase
class TodayEarningsState {
  final bool isLoading;
  final String? error;
  // From earnings_daily
  final int earnOrdersCount;
  final double earnTotal;
  final double growTotal;
  final double marketProfit;
  final double totalEarnings;
  final double netEarnings;
  final double hoursOnline;
  final double hourlyRate;
  final double distanceKm;
  // From earnings_monthly
  final double monthlyEarnTotal;
  final double monthlyGrowTotal;
  final double monthlyMarketTotal;
  final double monthlyNetEarnings;
  // Balance
  final double balance;
  final double pendingBalance;
  // Transactions
  final List<Map<String, dynamic>> recentTransactions;

  const TodayEarningsState({
    this.isLoading = true,
    this.error,
    this.earnOrdersCount = 0,
    this.earnTotal = 0,
    this.growTotal = 0,
    this.marketProfit = 0,
    this.totalEarnings = 0,
    this.netEarnings = 0,
    this.hoursOnline = 0,
    this.hourlyRate = 0,
    this.distanceKm = 0,
    this.monthlyEarnTotal = 0,
    this.monthlyGrowTotal = 0,
    this.monthlyMarketTotal = 0,
    this.monthlyNetEarnings = 0,
    this.balance = 0,
    this.pendingBalance = 0,
    this.recentTransactions = const [],
  });

  TodayEarningsState copyWith({
    bool? isLoading,
    String? error,
    int? earnOrdersCount,
    double? earnTotal,
    double? growTotal,
    double? marketProfit,
    double? totalEarnings,
    double? netEarnings,
    double? hoursOnline,
    double? hourlyRate,
    double? distanceKm,
    double? monthlyEarnTotal,
    double? monthlyGrowTotal,
    double? monthlyMarketTotal,
    double? monthlyNetEarnings,
    double? balance,
    double? pendingBalance,
    List<Map<String, dynamic>>? recentTransactions,
  }) {
    return TodayEarningsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      earnOrdersCount: earnOrdersCount ?? this.earnOrdersCount,
      earnTotal: earnTotal ?? this.earnTotal,
      growTotal: growTotal ?? this.growTotal,
      marketProfit: marketProfit ?? this.marketProfit,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      netEarnings: netEarnings ?? this.netEarnings,
      hoursOnline: hoursOnline ?? this.hoursOnline,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      distanceKm: distanceKm ?? this.distanceKm,
      monthlyEarnTotal: monthlyEarnTotal ?? this.monthlyEarnTotal,
      monthlyGrowTotal: monthlyGrowTotal ?? this.monthlyGrowTotal,
      monthlyMarketTotal: monthlyMarketTotal ?? this.monthlyMarketTotal,
      monthlyNetEarnings: monthlyNetEarnings ?? this.monthlyNetEarnings,
      balance: balance ?? this.balance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      recentTransactions: recentTransactions ?? this.recentTransactions,
    );
  }
}

class TodayEarningsNotifier extends StateNotifier<TodayEarningsState> {
  final EarningsRepository _repo = EarningsRepository();

  TodayEarningsNotifier() : super(const TodayEarningsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      // Fetch all data in parallel
      final dailyFuture = _repo.getTodayEarnings();
      final monthlyFuture = _repo.getMonthlyEarnings();
      final balanceFuture = _repo.getBalance();
      final pendingFuture = _repo.getPendingBalance();
      final txFuture = _repo.getRecentTransactions(limit: 5);

      final daily = await dailyFuture;
      final monthly = await monthlyFuture;
      final balance = await balanceFuture;
      final pendingBalance = await pendingFuture;
      final transactions = await txFuture;

      state = TodayEarningsState(
        isLoading: false,
        // Daily
        earnOrdersCount: (daily?['earn_orders_count'] as num?)?.toInt() ?? 0,
        earnTotal: (daily?['earn_total'] as num?)?.toDouble() ?? 0,
        growTotal: (daily?['grow_total'] as num?)?.toDouble() ?? 0,
        marketProfit: (daily?['market_profit'] as num?)?.toDouble() ?? 0,
        totalEarnings: (daily?['total_earnings'] as num?)?.toDouble() ?? 0,
        netEarnings: (daily?['net_earnings'] as num?)?.toDouble() ?? 0,
        hoursOnline: (daily?['hours_online'] as num?)?.toDouble() ?? 0,
        hourlyRate: (daily?['hourly_rate'] as num?)?.toDouble() ?? 0,
        distanceKm: (daily?['distance_km'] as num?)?.toDouble() ?? 0,
        // Monthly
        monthlyEarnTotal: (monthly?['earn_total'] as num?)?.toDouble() ?? 0,
        monthlyGrowTotal: (monthly?['grow_total'] as num?)?.toDouble() ?? 0,
        monthlyMarketTotal: (monthly?['market_total'] as num?)?.toDouble() ?? 0,
        monthlyNetEarnings: (monthly?['net_earnings'] as num?)?.toDouble() ?? 0,
        // Balance
        balance: balance,
        pendingBalance: pendingBalance,
        // Transactions
        recentTransactions: transactions,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final todayEarningsProvider =
    StateNotifierProvider<TodayEarningsNotifier, TodayEarningsState>(
  (ref) => TodayEarningsNotifier(),
);
