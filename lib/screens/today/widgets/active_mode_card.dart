import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';
import '../../../providers/earnings_provider.dart';
import '../../../providers/active_orders_provider.dart';
import '../../../services/rush_hour_service.dart';

class ActiveModeCard extends ConsumerWidget {
  const ActiveModeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final ordersState = ref.watch(activeOrdersProvider);
    final earnings = ref.watch(earningsProvider);
    final target = earnings.dailyTarget;
    final isRushHour = RushHourService.isRushHourNow();
    final availableOrders = ordersState.availableOrders;
    final activeOrders = ordersState.orders.where((o) => o.phase != OrderPhase.completed).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: AppColors.earningsGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active orders banner (if any)
          if (activeOrders.isNotEmpty)
            _buildActiveOrderBanner(context, cs, activeOrders),

          // Header
          _buildHeader(context, ref, cs, isRushHour, availableOrders.length),

          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),

          // Orders list
          _buildOrdersList(context, ref, cs, isRushHour, availableOrders),

          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),

          // Daily target
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: _buildDailyTarget(cs, target),
          ),
        ],
      ),
    );
  }

  /// Banner ordini attivi in corso
  Widget _buildActiveOrderBanner(BuildContext context, ColorScheme cs, List<ActiveOrder> activeOrders) {
    return GestureDetector(
      onTap: () => context.push('/today/delivery'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
        decoration: BoxDecoration(
          color: AppColors.routeBlue.withValues(alpha: 0.15),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.lg - 1)),
        ),
        child: Row(
          children: [
            Icon(Icons.delivery_dining, size: 18, color: AppColors.routeBlue),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                '${activeOrders.length} ${activeOrders.length == 1 ? 'ordine in corso' : 'ordini in corso'}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.routeBlue,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.routeBlue),
          ],
        ),
      ),
    );
  }

  /// Header con conteggio ordini e refresh
  Widget _buildHeader(BuildContext context, WidgetRef ref, ColorScheme cs, bool isRushHour, int orderCount) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              color: AppColors.earningsGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: AppColors.earningsGreen,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORDINI VICINI',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$orderCount disponibili',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (isRushHour) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.earningsGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, size: 14, color: AppColors.earningsGreen),
                  const SizedBox(width: 4),
                  Text(
                    '2X',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.earningsGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
          ],
          IconButton(
            onPressed: () => ref.read(activeOrdersProvider.notifier).refreshAvailableOrders(),
            icon: Icon(Icons.refresh, color: cs.onSurfaceVariant, size: 22),
            tooltip: 'Aggiorna ordini',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// Lista ordini scrollabile
  Widget _buildOrdersList(BuildContext context, WidgetRef ref, ColorScheme cs, bool isRushHour, List<ActiveOrder> orders) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: cs.outlineVariant.withValues(alpha: 0.2),
        indent: Spacing.lg,
        endIndent: Spacing.lg,
      ),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderRow(context, ref, cs, order, isRushHour, index == 0);
      },
    );
  }

  /// Singola riga ordine
  Widget _buildOrderRow(BuildContext context, WidgetRef ref, ColorScheme cs, ActiveOrder order, bool isRushHour, bool isFirst) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 48,
            margin: const EdgeInsets.only(right: Spacing.md),
            decoration: BoxDecoration(
              color: isFirst ? AppColors.earningsGreen : cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.dealerName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.customerAddress} • ${order.distanceKm} km',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isRushHour) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '€${order.baseEarning.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '€${order.totalEarning.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.earningsGreen,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  '€${order.baseEarning.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.earningsGreen,
                  ),
                ),
              ],
              const SizedBox(height: Spacing.sm),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(activeOrdersProvider.notifier).acceptOrder(order);
                    context.push('/today/delivery', extra: order.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.earningsGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ACCETTA',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Barra obiettivo giornaliero
  Widget _buildDailyTarget(ColorScheme cs, dynamic target) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: Spacing.sm),
                Text(
                  'Obiettivo: € ${target.currentAmount.toStringAsFixed(0)} / € ${target.targetAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Text(
              '${target.progressPercent}%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: target.isComplete ? AppColors.earningsGreen : AppColors.routeBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: target.progress,
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              target.isComplete ? AppColors.earningsGreen : AppColors.routeBlue,
            ),
          ),
        ),
      ],
    );
  }
}
