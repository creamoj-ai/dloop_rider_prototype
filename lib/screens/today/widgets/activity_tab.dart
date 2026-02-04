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
  String _filterStatus = 'tutti'; // tutti, consegnato, in_corso, rifiutato
  String _sortBy = 'recenti'; // recenti, meno_recenti

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final earnings = ref.watch(earningsProvider);
    // Mostra TUTTI gli ordini, ordinati per più recenti prima
    final allOrders = earnings.todayOrders
        .toList()
        .reversed
        .toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (sempre visibile)
          _buildHeader(cs, allOrders.length),
          // Lista ordini (solo se espansa)
          if (_isExpanded)
            _buildOrdersList(cs, allOrders),
        ],
      ),
    );
  }

  /// Header tab con conteggio - sfondo nero, testo arancio centrato
  Widget _buildHeader(ColorScheme cs, int count) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: _isExpanded
              ? const BorderRadius.vertical(top: Radius.circular(16))
              : BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.turboOrange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 20,
              color: AppColors.turboOrange,
            ),
            const SizedBox(width: 10),
            Text(
              'Attività di oggi',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.turboOrange,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.turboOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.turboOrange,
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
                color: AppColors.turboOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Filtra ordini per stato
  List<Order> _filterOrders(List<Order> orders) {
    var filtered = orders;

    // Applica filtro stato
    switch (_filterStatus) {
      case 'consegnato':
        filtered = orders.where((o) => o.status == OrderStatus.delivered).toList();
        break;
      case 'in_corso':
        filtered = orders.where((o) =>
          o.status == OrderStatus.pending ||
          o.status == OrderStatus.accepted ||
          o.status == OrderStatus.pickedUp
        ).toList();
        break;
      case 'rifiutato':
        filtered = orders.where((o) => o.status == OrderStatus.cancelled).toList();
        break;
    }

    // Applica ordinamento
    if (_sortBy == 'meno_recenti') {
      filtered = filtered.reversed.toList();
    }

    return filtered;
  }

  /// Lista ordini con stato
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
                'Nessuna attività ancora',
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

    final filteredOrders = _filterOrders(orders);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Barra filtri e ordinamento
          _buildFiltersBar(cs),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          // Lista filtrata
          if (filteredOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Nessun ordine con questo filtro',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
            )
          else
            ...filteredOrders.map((order) => _buildOrderItem(cs, order)),
        ],
      ),
    );
  }

  /// Barra filtri e ordinamento
  Widget _buildFiltersBar(ColorScheme cs) {
    return Row(
      children: [
        // Filtro stato
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(cs, 'Tutti', 'tutti'),
                const SizedBox(width: 6),
                _buildFilterChip(cs, 'Consegnati', 'consegnato'),
                const SizedBox(width: 6),
                _buildFilterChip(cs, 'In corso', 'in_corso'),
                const SizedBox(width: 6),
                _buildFilterChip(cs, 'Rifiutati', 'rifiutato'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Ordinamento
        InkWell(
          onTap: () {
            setState(() {
              _sortBy = _sortBy == 'recenti' ? 'meno_recenti' : 'recenti';
            });
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _sortBy == 'recenti' ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _sortBy == 'recenti' ? 'Recenti' : 'Meno recenti',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Chip filtro singolo
  Widget _buildFilterChip(ColorScheme cs, String label, String value) {
    final isSelected = _filterStatus == value;
    return InkWell(
      onTap: () => setState(() => _filterStatus = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.turboOrange.withValues(alpha: 0.15)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.turboOrange.withValues(alpha: 0.5))
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.turboOrange : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// Stato ordine in italiano con colore
  ({String label, Color color, IconData icon}) _getStatusInfo(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return (
          label: 'Da accettare',
          color: AppColors.routeBlue,
          icon: Icons.hourglass_empty,
        );
      case OrderStatus.accepted:
        return (
          label: 'Accettato',
          color: AppColors.turboOrange,
          icon: Icons.check_circle_outline,
        );
      case OrderStatus.pickedUp:
        return (
          label: 'Ritirato',
          color: AppColors.turboOrange,
          icon: Icons.takeout_dining,
        );
      case OrderStatus.delivered:
        return (
          label: 'Consegnato',
          color: AppColors.earningsGreen,
          icon: Icons.check_circle,
        );
      case OrderStatus.cancelled:
        return (
          label: 'Rifiutato',
          color: const Color(0xFFEF4444),
          icon: Icons.cancel,
        );
    }
  }

  /// Singolo ordine nella lista con stato
  Widget _buildOrderItem(ColorScheme cs, Order order) {
    final statusInfo = _getStatusInfo(order.status);
    final isRush = order.rushMultiplier > 1;

    // Usa l'orario appropriato in base allo stato
    String time = '--:--';
    if (order.deliveredAt != null) {
      time = '${order.deliveredAt!.hour.toString().padLeft(2, '0')}:${order.deliveredAt!.minute.toString().padLeft(2, '0')}';
    } else if (order.pickedUpAt != null) {
      time = '${order.pickedUpAt!.hour.toString().padLeft(2, '0')}:${order.pickedUpAt!.minute.toString().padLeft(2, '0')}';
    } else if (order.acceptedAt != null) {
      time = '${order.acceptedAt!.hour.toString().padLeft(2, '0')}:${order.acceptedAt!.minute.toString().padLeft(2, '0')}';
    } else {
      time = '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icona stato
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusInfo.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              statusInfo.icon,
              size: 16,
              color: statusInfo.color,
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                // Badge stato
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusInfo.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusInfo.label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusInfo.color,
                        ),
                      ),
                    ),
                    if (isRush) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.earningsGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
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
          ),
          // Guadagno
          Text(
            '€ ${order.totalEarning.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: order.status == OrderStatus.delivered
                  ? AppColors.earningsGreen
                  : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
