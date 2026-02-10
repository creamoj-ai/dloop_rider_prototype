import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class KpiStrip extends StatelessWidget {
  const KpiStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'GUADAGNO',
            value: '€ 142',
            goal: '€ 180',
            progress: 0.79,
            color: AppColors.earningsGreen,
            icon: Icons.euro,
            onTap: () => context.go('/money'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            label: 'ORDINI',
            value: '8',
            goal: '12',
            progress: 0.67,
            color: AppColors.routeBlue,
            icon: Icons.inventory_2,
            onTap: () => _showTodayOrders(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            label: 'MYSHOP',
            value: '3',
            goal: '10',
            progress: 0.30,
            color: AppColors.turboOrange,
            icon: Icons.storefront,
            suffix: 'nuovi',
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
      isScrollControlled: true,
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
                  const Icon(Icons.storefront, color: AppColors.turboOrange, size: 20),
                  const SizedBox(width: 8),
                  Text('MyShop', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.earningsGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text('€45', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.earningsGreen)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ShopStat(label: 'Prodotti', value: '12', color: AppColors.turboOrange),
                  const SizedBox(width: 8),
                  _ShopStat(label: 'Ordini', value: '6', color: AppColors.routeBlue),
                  const SizedBox(width: 8),
                  _ShopStat(label: 'Comm.', value: '€180', color: AppColors.earningsGreen),
                ],
              ),
              const SizedBox(height: 14),
              Text('Ordini in attesa', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
              const SizedBox(height: 8),
              _ShopOrderItem(customer: 'Anna V.', product: 'Energy Drink', amount: '€15', status: 'Nuovo', statusColor: AppColors.routeBlue),
              _ShopOrderItem(customer: 'Paolo G.', product: 'Snack Box', amount: '€12', status: 'In corso', statusColor: AppColors.turboOrange),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () { Navigator.pop(context); context.go('/market'); },
                  child: Text('Vai al Market →', style: GoogleFonts.inter(color: AppColors.turboOrange, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTodayOrders(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                    decoration: BoxDecoration(color: AppColors.earningsGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text('8 OK', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.earningsGreen)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _OrderItem(time: '14:32', restaurant: 'Pizzeria Mario', address: 'Via Roma 15', earning: '€4.50', status: 'completed'),
              _OrderItem(time: '13:58', restaurant: 'Sushi Zen', address: 'C.so Buenos Aires', earning: '€5.80', status: 'completed'),
              _OrderItem(time: '13:21', restaurant: "McDonald's", address: 'Piazza Duomo', earning: '€3.90', status: 'completed'),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () { Navigator.pop(context); context.go('/money'); },
                  child: Text('Vedi tutti →', style: GoogleFonts.inter(color: AppColors.routeBlue, fontWeight: FontWeight.w600, fontSize: 13)),
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
          // Time
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
          // Status dot
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
          // Details
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
          // Earning
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
            color: progress >= 0.75 ? color.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: label + icon
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
            // Value
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
            // Progress bar + percentage
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

class _ShopStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ShopStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopOrderItem extends StatelessWidget {
  final String customer;
  final String product;
  final String amount;
  final String status;
  final Color statusColor;

  const _ShopOrderItem({
    required this.customer,
    required this.product,
    required this.amount,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  product,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.earningsGreen,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
