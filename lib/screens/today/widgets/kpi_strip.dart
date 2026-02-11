import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';
import '../../../providers/earnings_provider.dart';
import '../../../providers/orders_stream_provider.dart';
import '../../../models/order.dart';

class KpiStrip extends ConsumerWidget {
  const KpiStrip({super.key});

  static const double _dailyGoal = 100.0;
  static const int _ordersGoal = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsState = ref.watch(earningsProvider);
    final completedOrders = ref.watch(todayCompletedOrdersProvider);

    final todayEarnings = earningsState.todayTotal;
    final ordersCount = completedOrders.isNotEmpty
        ? completedOrders.length
        : earningsState.ordersCount;

    final earningsProgress = (todayEarnings / _dailyGoal).clamp(0.0, 1.0);
    final ordersProgress = (ordersCount / _ordersGoal).clamp(0.0, 1.0);

    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'GUADAGNO',
            value: '\u20AC ${todayEarnings.toStringAsFixed(0)}',
            goal: '\u20AC ${_dailyGoal.toStringAsFixed(0)}',
            progress: earningsProgress,
            color: AppColors.earningsGreen,
            icon: Icons.euro,
            onTap: () => context.go('/money'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            label: 'ORDINI',
            value: '$ordersCount',
            goal: '$_ordersGoal',
            progress: ordersProgress,
            color: AppColors.routeBlue,
            icon: Icons.inventory_2,
            onTap: () => _showTodayOrders(context, ref),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            label: 'MYSHOP',
            value: '-',
            goal: 'Soon',
            progress: 0.0,
            color: AppColors.turboOrange,
            icon: Icons.storefront,
            suffix: 'soon',
            onTap: () => _showShopOrders(context),
          ),
        ),
      ],
    );
  }

  void _showShopOrders(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.turboOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.storefront, color: AppColors.turboOrange, size: 40),
            ),
            const SizedBox(height: 16),
            Text('MyShop', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Il marketplace rider arriva presto!\nPotrai vendere prodotti direttamente ai tuoi clienti.',
              style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.turboOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Prossimamente', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.turboOrange)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTodayOrders(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final earningsState = ref.read(earningsProvider);
    final deliveredOrders = earningsState.todayOrders
        .where((o) => o.status == OrderStatus.delivered)
        .toList()
      ..sort((a, b) => (b.deliveredAt ?? b.createdAt).compareTo(a.deliveredAt ?? a.createdAt));

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
                  const Icon(Icons.inventory_2, color: AppColors.routeBlue, size: 20),
                  const SizedBox(width: 8),
                  Text('Ordini oggi', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.earningsGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text('${deliveredOrders.length} OK', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.earningsGreen)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (deliveredOrders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Nessun ordine completato oggi',
                      style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ...deliveredOrders.take(10).map((order) {
                  final time = order.deliveredAt != null
                      ? '${order.deliveredAt!.hour.toString().padLeft(2, '0')}:${order.deliveredAt!.minute.toString().padLeft(2, '0')}'
                      : '--:--';
                  return _OrderItem(
                    time: time,
                    restaurant: order.restaurantName,
                    address: order.customerAddress,
                    earning: '\u20AC${order.totalEarning.toStringAsFixed(2)}',
                    status: 'completed',
                  );
                }),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () { Navigator.pop(context); context.go('/money'); },
                  child: Text('Vedi tutti \u2192', style: GoogleFonts.inter(color: AppColors.routeBlue, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final String time;
  final String restaurant;
  final String address;
  final String earning;
  final String status;

  const _OrderItem({
    required this.time,
    required this.restaurant,
    required this.address,
    required this.earning,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: status == 'completed'
                  ? AppColors.earningsGreen
                  : AppColors.turboOrange,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  address,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            earning,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.earningsGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String goal;
  final double progress;
  final Color color;
  final IconData icon;
  final String? suffix;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.goal,
    required this.progress,
    required this.color,
    required this.icon,
    this.suffix,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final percentage = (progress * 100).toInt();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: progress >= 0.75 ? color.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    suffix!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$percentage%',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: progress >= 0.75 ? color : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
