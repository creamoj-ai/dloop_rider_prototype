import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/dloop_card.dart';
import '../../../providers/rider_stats_provider.dart';

class StatsOnlyCard extends ConsumerWidget {
  const StatsOnlyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(riderStatsProvider);

    return statsAsync.when(
      data: (stats) => _buildCard(stats),
      loading: () => _buildCard(const RiderStats()),
      error: (_, __) => _buildCard(const RiderStats()),
    );
  }

  Widget _buildCard(RiderStats stats) {
    final ordersStr = _formatNumber(stats.lifetimeOrders);
    final earningsStr = '\u20AC ${_formatNumber(stats.lifetimeEarnings.round())}';
    final kmStr = _formatNumber(stats.lifetimeDistanceKm.round());
    final ratingStr = '${stats.avgRating.toStringAsFixed(1)} \u2605';
    final bestDayStr = '\u20AC ${stats.bestDayEarnings.toStringAsFixed(2)}';
    final hoursStr = _formatNumber(stats.lifetimeHoursOnline.round());

    return DloopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATISTICHE LIFETIME',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9E9E9E),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _gridStat(ordersStr, 'Ordini totali'),
              _gridStat(earningsStr, 'Guadagno totale'),
              _gridStat(kmStr, 'Km percorsi'),
              _gridStat(ratingStr, 'Rating medio'),
              _gridStat(bestDayStr, 'Best day'),
              _gridStat(hoursStr, 'Ore totali'),
            ],
          ),
        ],
      ),
    );
  }

  /// Format number with dot separator (1247 → "1.247")
  String _formatNumber(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  Widget _gridStat(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF9E9E9E),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
