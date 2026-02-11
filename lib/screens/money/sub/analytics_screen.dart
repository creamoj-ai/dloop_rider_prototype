import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/earning.dart';
import '../../../providers/transactions_provider.dart';
import '../../../providers/rider_stats_provider.dart';
import '../../../theme/tokens.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final monthlyByType = ref.watch(monthlyByTypeProvider);
    final statsAsync = ref.watch(riderStatsProvider);
    final txAsync = ref.watch(transactionsStreamProvider);

    // Earn = delivery this month
    final earnMonth =
        monthlyByType[EarningType.delivery]?.total ?? 0;
    // Grow = network this month
    final growMonth =
        monthlyByType[EarningType.network]?.total ?? 0;

    // Weekly trend: this week vs last week
    final weekTrend = txAsync.when(
      data: (txs) => _computeWeeklyTrend(txs),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    // Best day from rider_stats
    final stats = statsAsync.when(
      data: (s) => s,
      loading: () => const RiderStats(),
      error: (_, __) => const RiderStats(),
    );

    return Scaffold(
      appBar: AppBar(
          title: Text('Analytics',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(cs, 'Earn vs Grow ROI', AppColors.turboOrange, [
              _stat('Earn',
                  '\u20AC ${earnMonth.toStringAsFixed(0)}/mese',
                  AppColors.turboOrange),
              _stat('Grow',
                  '\u20AC ${growMonth.toStringAsFixed(0)}/mese',
                  AppColors.earningsGreen),
            ]),
            const SizedBox(height: 12),
            _card(cs, 'Trend Settimanale', AppColors.earningsGreen, [
              _stat(
                '${weekTrend >= 0 ? '+' : ''}${weekTrend.toStringAsFixed(0)}%',
                'vs settimana scorsa',
                weekTrend >= 0
                    ? AppColors.earningsGreen
                    : AppColors.urgentRed,
              ),
            ]),
            const SizedBox(height: 12),
            _card(cs, 'Best Day', AppColors.bonusPurple, [
              _stat(
                _formatBestDay(stats.bestDayDate),
                '\u20AC ${stats.bestDayEarnings.toStringAsFixed(2)}',
                AppColors.bonusPurple,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  double _computeWeeklyTrend(List<Earning> txs) {
    final now = DateTime.now();
    final thisWeekStart =
        now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart =
        thisWeekStart.subtract(const Duration(days: 7));

    final thisWeekEarnings = txs
        .where((t) =>
            t.status == EarningStatus.completed &&
            t.dateTime.isAfter(
                DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day)))
        .fold(0.0, (sum, t) => sum + t.amount);

    final lastWeekEarnings = txs
        .where((t) =>
            t.status == EarningStatus.completed &&
            t.dateTime.isAfter(
                DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day)) &&
            t.dateTime.isBefore(
                DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day)))
        .fold(0.0, (sum, t) => sum + t.amount);

    if (lastWeekEarnings == 0) return thisWeekEarnings > 0 ? 100 : 0;
    return ((thisWeekEarnings - lastWeekEarnings) / lastWeekEarnings) * 100;
  }

  String _formatBestDay(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      const days = ['Lunedi', 'Martedi', 'Mercoledi', 'Giovedi', 'Venerdi', 'Sabato', 'Domenica'];
      return days[date.weekday - 1];
    } catch (_) {
      return dateStr;
    }
  }

  Widget _card(
      ColorScheme cs, String title, Color accent, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF9E9E9E))),
        ],
      ),
    );
  }
}
