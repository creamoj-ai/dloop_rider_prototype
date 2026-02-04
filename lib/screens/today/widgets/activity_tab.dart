import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';
import '../../../providers/earnings_provider.dart';
import '../../../models/order.dart';

/// Tab espandibile "Attività" - mostra lista ordini completati oggi
class ActivityTab extends ConsumerStatefulWidget {
  const ActivityTab({super.key});

  @override
  ConsumerState<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<ActivityTab> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final earnings = ref.watch(earningsProvider);
    final completedOrders = earnings.todayOrders
        .where((o) => o.status == OrderStatus.delivered)
        .toList()
        .reversed
        .toList(); // Più recenti prima

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _isExpanded ? cs.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: _isExpanded
            ? Border.all(color: AppColors.turboOrange, width: 1)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (sempre visibile)
          _buildHeader(cs, completedOrders.length),
          // Lista ordini (solo se espansa)
          if (_isExpanded)
            _buildOrdersList(cs, completedOrders),
        ],
      ),
    );
  }

  /// Header tab con conteggio - colori invertiti, testo centrato
  Widget _buildHeader(ColorScheme cs, int count) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.turboOrange,
          borderRadius: _isExpanded
              ? const BorderRadius.vertical(top: Radius.circular(16))
              : BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              'Attività di oggi',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down,
                size: 22,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lista ordini completati
  Widget _buildOrdersList(ColorScheme cs, List<Order> orders) {
    if (orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(
                Icons.delivery_dining,
                size: 32,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Nessuna consegna ancora',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Accetta il primo ordine!',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          ...orders.map((order) => _buildOrderItem(cs, order)),
        ],
      ),
    );
  }

  /// Singolo ordine nella lista
  Widget _buildOrderItem(ColorScheme cs, Order order) {
    final time = order.deliveredAt != null
        ? '${order.deliveredAt!.hour.toString().padLeft(2, '0')}:${order.deliveredAt!.minute.toString().padLeft(2, '0')}'
        : '--:--';
    final isRush = order.rushMultiplier > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info ordine
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.restaurantName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.customerAddress} • $time',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Guadagno + badge 2X
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+ € ${order.totalEarning.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.earningsGreen,
                ),
              ),
              if (isRush) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.earningsGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '2X',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.earningsGreen,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
