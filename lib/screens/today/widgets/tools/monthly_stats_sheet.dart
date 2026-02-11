import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/tokens.dart';
import '../../../../providers/monthly_stats_provider.dart';

class MonthlyStatsSheet extends ConsumerWidget {
  const MonthlyStatsSheet({super.key});

  static const _monthNames = [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final statsAsync = ref.watch(monthlyStatsProvider);

    return statsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator(color: AppColors.routeBlue)),
      ),
      error: (_, __) => _buildContent(cs, const MonthlyStats()),
      data: (stats) => _buildContent(cs, stats),
    );
  }

  Widget _buildContent(ColorScheme cs, MonthlyStats stats) {
    final now = DateTime.now();
    final monthName = _monthNames[now.month - 1];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.routeBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month, color: AppColors.routeBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stats $monthName', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
                    Text('${now.year}', style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Total earnings
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.earningsGreen.withValues(alpha: 0.2), AppColors.earningsGreen.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.earningsGreen.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text('Guadagno totale', style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(
                  '\u20AC ${stats.totalEarnings.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.earningsGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats grid
          Row(
            children: [
              _StatCell(label: 'Ordini', value: '${stats.totalOrders}', color: AppColors.routeBlue),
              const SizedBox(width: 10),
              _StatCell(label: 'Ore online', value: '${stats.totalHoursOnline.toStringAsFixed(1)}h', color: AppColors.bonusPurple),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatCell(label: 'Km percorsi', value: '${stats.totalDistanceKm.toStringAsFixed(1)}', color: AppColors.turboOrange),
              const SizedBox(width: 10),
              _StatCell(label: 'Giorni lavorati', value: '${stats.workDaysCount}', color: AppColors.statsGold),
            ],
          ),
          const SizedBox(height: 20),

          // Averages
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Media per ordine', style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant)),
                    Text('\u20AC${stats.avgPerOrder.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Media oraria', style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant)),
                    Text('\u20AC${stats.avgPerHour.toStringAsFixed(2)}/h', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  ],
                ),
                if (stats.bestDayEarnings > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Miglior giorno', style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant)),
                      Text(
                        '\u20AC${stats.bestDayEarnings.toStringAsFixed(2)} (${_formatDate(stats.bestDayDate)})',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.earningsGreen),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.length < 10) return '-';
    final parts = isoDate.split('-');
    return '${parts[2]}/${parts[1]}';
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
