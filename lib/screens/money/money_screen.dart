import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/tokens.dart';
import '../../models/earning.dart';
import '../../widgets/dloop_top_bar.dart';
import '../../widgets/invite_sheet.dart';
import '../../widgets/header_sheets.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/monthly_stats_provider.dart';
import 'widgets/balance_hero.dart';
import 'widgets/income_streams.dart';
import 'widgets/recent_activity.dart';
import 'widgets/history_bottom_sheet.dart';

class MoneyScreen extends ConsumerWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          DloopTopBar(
            isOnline: true,
            notificationCount: 2,
            searchHint: 'Cerca transazioni...',
            onSearchTap: () => SearchSheet.show(context, hint: 'Cerca transazioni...'),
            onNotificationTap: () => NotificationsSheet.show(context),
            onQuickActionTap: () => QuickActionsSheet.show(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick actions row
                  Row(
                    children: [
                      _buildQuickAction(
                        context,
                        icon: Icons.history,
                        label: 'Storico',
                        color: AppColors.routeBlue,
                        onTap: () => HistoryBottomSheet.show(context),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickAction(
                        context,
                        icon: Icons.analytics_outlined,
                        label: 'Analytics',
                        color: AppColors.statsGold,
                        onTap: () => _showAnalyticsSheet(context, ref),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickAction(
                        context,
                        icon: Icons.receipt_long,
                        label: 'Transazioni',
                        color: AppColors.turboOrange,
                        onTap: () => _showTransactionsSheet(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const BalanceHero(),
                  const SizedBox(height: 16),
                  const IncomeStreams(),
                  const SizedBox(height: 24),
                  _buildInviteEarnCard(context, cs),
                  const SizedBox(height: 24),
                  const RecentActivity(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnalyticsSheet(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final earningsState = ref.read(earningsProvider);
    final monthlyStats = ref.read(monthlyStatsProvider);

    // Compute real averages
    final hourlyRate = earningsState.hourlyRate;
    final avgPerOrder = earningsState.avgPerOrder;

    // Monthly stats for deliveries/day and avg distance
    double deliveriesPerDay = 0;
    double avgDistanceKm = 0;
    monthlyStats.whenData((stats) {
      if (stats.workDaysCount > 0) {
        deliveriesPerDay = stats.totalOrders / stats.workDaysCount;
      }
      if (stats.totalOrders > 0) {
        avgDistanceKm = stats.totalDistanceKm / stats.totalOrders;
      }
    });

    // Avg delivery time from today orders
    final deliveredOrders = earningsState.todayOrders.where((o) =>
      o.status.name == 'delivered' && o.acceptedAt != null && o.deliveredAt != null
    ).toList();
    double avgMinutes = 0;
    if (deliveredOrders.isNotEmpty) {
      final totalMin = deliveredOrders.fold(0.0, (sum, o) =>
        sum + o.deliveredAt!.difference(o.acceptedAt!).inMinutes);
      avgMinutes = totalMin / deliveredOrders.length;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: AppColors.statsGold, size: 20),
                  const SizedBox(width: 8),
                  Text('Analytics', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                ],
              ),
              const SizedBox(height: 16),
              _buildAnalyticRow('Media oraria', '\u20AC${hourlyRate.toStringAsFixed(2)}/h', AppColors.earningsGreen),
              _buildAnalyticRow('Media per ordine', '\u20AC${avgPerOrder.toStringAsFixed(2)}', AppColors.earningsGreen),
              _buildAnalyticRow('Consegne/giorno', deliveriesPerDay > 0 ? deliveriesPerDay.toStringAsFixed(1) : '-', AppColors.routeBlue),
              _buildAnalyticRow('Distanza media', avgDistanceKm > 0 ? '${avgDistanceKm.toStringAsFixed(1)} km' : '-', AppColors.turboOrange),
              _buildAnalyticRow('Tempo medio', avgMinutes > 0 ? '${avgMinutes.toStringAsFixed(0)} min' : '-', AppColors.bonusPurple),
              const SizedBox(height: 16),
              Text('Trend settimanale', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
              const SizedBox(height: 8),
              Container(
                height: 60,
                decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('Grafico in sviluppo', style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9E9E9E))),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  void _showTransactionsSheet(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final todayTxs = ref.read(todayTransactionsProvider);

    final typeIcons = {
      EarningType.delivery: Icons.bolt,
      EarningType.network: Icons.eco,
      EarningType.market: Icons.shopping_cart,
    };
    final typeColors = {
      EarningType.delivery: AppColors.turboOrange,
      EarningType.network: AppColors.earningsGreen,
      EarningType.market: AppColors.bonusPurple,
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppColors.turboOrange, size: 20),
                  const SizedBox(width: 8),
                  Text('Transazioni', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.earningsGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text('${todayTxs.length} oggi', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.earningsGreen)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (todayTxs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('Nessuna transazione oggi', style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant)),
                  ),
                )
              else
                ...todayTxs.take(10).map((tx) {
                  final time = '${tx.dateTime.hour.toString().padLeft(2, '0')}:${tx.dateTime.minute.toString().padLeft(2, '0')}';
                  final color = typeColors[tx.type] ?? AppColors.turboOrange;
                  return _buildTxItem(cs, tx.description, time, '+\u20AC${tx.amount.toStringAsFixed(2)}', color, typeIcons[tx.type] ?? Icons.bolt);
                }),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Chiudi', style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTxItem(ColorScheme cs, String desc, String time, String amount, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(time, style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text(amount, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.earningsGreen)),
        ],
      ),
    );
  }

  Widget _buildInviteEarnCard(BuildContext context, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.earningsGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.earningsGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: AppColors.earningsGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Guadagna di piu',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invita amici',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\u20AC10 per ogni rider attivo',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => InviteSheet.show(context),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.earningsGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'INVITA',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prossimamente',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.turboOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SOON',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.turboOrange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
