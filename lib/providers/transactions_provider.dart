import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/earning.dart';
import '../services/earnings_service.dart';

class PendingInfo {
  final double total;
  final int count;
  const PendingInfo({required this.total, required this.count});
}

class MonthlyTypeInfo {
  final double total;
  final int count;
  const MonthlyTypeInfo({required this.total, required this.count});
}

/// Real-time stream of all transactions for the current rider
final transactionsStreamProvider = StreamProvider<List<Earning>>((ref) {
  return EarningsService.subscribeToEarnings();
});

/// All completed transactions (total balance)
final completedBalanceProvider = Provider<double>((ref) {
  final txAsync = ref.watch(transactionsStreamProvider);
  return txAsync.when(
    data: (txs) => txs
        .where((t) => t.status == EarningStatus.completed)
        .fold(0.0, (sum, t) => sum + t.amount),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Sum of pending transactions
final pendingBalanceProvider = Provider<double>((ref) {
  final txAsync = ref.watch(transactionsStreamProvider);
  return txAsync.when(
    data: (txs) => txs
        .where((t) => t.status == EarningStatus.pending)
        .fold(0.0, (sum, t) => sum + t.amount),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Pending transactions grouped by type (for BalanceHero breakdown)
final pendingByTypeProvider = Provider<Map<EarningType, PendingInfo>>((ref) {
  final txAsync = ref.watch(transactionsStreamProvider);
  return txAsync.when(
    data: (txs) {
      final pending = txs.where((t) => t.status == EarningStatus.pending).toList();
      final map = <EarningType, PendingInfo>{};
      for (final type in EarningType.values) {
        final ofType = pending.where((t) => t.type == type).toList();
        if (ofType.isNotEmpty) {
          map[type] = PendingInfo(
            total: ofType.fold(0.0, (s, t) => s + t.amount),
            count: ofType.length,
          );
        }
      }
      return map;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Monthly transactions by type (for IncomeStreams)
final monthlyByTypeProvider = Provider<Map<EarningType, MonthlyTypeInfo>>((ref) {
  final txAsync = ref.watch(transactionsStreamProvider);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);

  return txAsync.when(
    data: (txs) {
      final thisMonth = txs.where((t) =>
          t.status == EarningStatus.completed &&
          t.dateTime.isAfter(monthStart));
      final map = <EarningType, MonthlyTypeInfo>{};
      for (final type in EarningType.values) {
        final ofType = thisMonth.where((t) => t.type == type).toList();
        map[type] = MonthlyTypeInfo(
          total: ofType.fold(0.0, (s, t) => s + t.amount),
          count: ofType.length,
        );
      }
      return map;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Recent transactions (last 5, for RecentActivity)
final recentTransactionsProvider = Provider<List<Earning>>((ref) {
  final txAsync = ref.watch(transactionsStreamProvider);
  return txAsync.when(
    data: (txs) => txs.take(5).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Today's transactions (for MoneyScreen transactions sheet)
final todayTransactionsProvider = Provider<List<Earning>>((ref) {
  final txAsync = ref.watch(transactionsStreamProvider);
  final todayStart = DateTime.now().copyWith(
    hour: 0, minute: 0, second: 0, millisecond: 0,
  );
  return txAsync.when(
    data: (txs) => txs.where((t) => t.dateTime.isAfter(todayStart)).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// All transactions list (for HistoryBottomSheet)
final allTransactionsProvider = Provider<List<Earning>>((ref) {
  final txAsync = ref.watch(transactionsStreamProvider);
  return txAsync.when(
    data: (txs) => txs,
    loading: () => [],
    error: (_, __) => [],
  );
});
