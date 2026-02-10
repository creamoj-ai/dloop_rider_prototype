import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/dloop_card.dart';
import '../../../providers/orders_stream_provider.dart';
import '../../../providers/session_provider.dart';

class TodayStatsCard extends ConsumerWidget {
  const TodayStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedOrders = ref.watch(todayCompletedOrdersProvider);
    final totalEarnings = ref.watch(todayStreamEarningsProvider);
    final session = ref.watch(activeSessionProvider);

    final ordersCount = completedOrders.length;
    final hours = session.activeMinutes / 60.0;
    final hoursStr = hours > 0
        ? '${hours.toStringAsFixed(1)}h'
        : '0h';
    final earningsStr = totalEarnings.toStringAsFixed(2);

    return DloopCard(
      child: Column(
        children: [
          // Header centrato
          Center(
            child: Text(
              'OGGI',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Grid 3 colonne
          Row(
            children: [
              _statColumn(
                context,
                icon: Icons.shopping_bag_outlined,
                value: '$ordersCount',
                label: 'Ordini',
                color: AppColors.turboOrange,
              ),
              const SizedBox(width: 12),
              _statColumn(
                context,
                icon: Icons.schedule,
                value: hoursStr,
                label: 'Ore',
                color: AppColors.earningsGreen,
              ),
              const SizedBox(width: 12),
              _statColumn(
                context,
                icon: Icons.euro,
                value: earningsStr,
                label: 'Guadagno',
                color: AppColors.bonusPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
