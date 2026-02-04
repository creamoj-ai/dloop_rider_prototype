import 'package:flutter/material.dart';
import '../models/order.dart';

/// Card che mostra un ordine con breakdown completo dei guadagni
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onAccept;
  final VoidCallback? onPickup;
  final VoidCallback? onDeliver;
  final bool showActions;

  const OrderCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onPickup,
    this.onDeliver,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: order.isRushHour
            ? const BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con ristorante e badge rush
            _buildHeader(),
            const SizedBox(height: 12),

            // Info consegna
            _buildDeliveryInfo(),
            const Divider(height: 24, color: Color(0xFF2A2A2E)),

            // Breakdown guadagni
            _buildEarningsBreakdown(),
            const Divider(height: 16, color: Color(0xFF2A2A2E)),

            // Totale
            _buildTotal(),

            // Azioni (se abilitate)
            if (showActions && _shouldShowActions()) ...[
              const SizedBox(height: 16),
              _buildActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.restaurant, color: Colors.orange, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.restaurantName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusColor(),
                ),
              ),
            ],
          ),
        ),
        if (order.isRushHour) const _RushBadge(),
      ],
    );
  }

  Widget _buildDeliveryInfo() {
    return Row(
      children: [
        _InfoChip(
          icon: Icons.route,
          label: '${order.distanceKm.toStringAsFixed(1)} km',
        ),
        const SizedBox(width: 12),
        _InfoChip(
          icon: Icons.timer_outlined,
          label: '~${order.estimatedMinutes} min',
        ),
      ],
    );
  }

  Widget _buildEarningsBreakdown() {
    return Column(
      children: [
        _EarningRow(
          label: 'Base (${order.distanceKm.toStringAsFixed(1)}km × €${Order.ratePerKm.toStringAsFixed(2)})',
          amount: order.baseEarning,
        ),
        if (order.isRushHour)
          _EarningRow(
            label: '🔥 Rush Hour (×${order.rushMultiplier.toInt()})',
            amount: order.rushBonus,
            isBonus: true,
          ),
        if (order.bonusEarning > 0)
          _EarningRow(
            label: '⭐ Bonus Performance',
            amount: order.bonusEarning,
            isBonus: true,
          ),
        if (order.tipAmount > 0)
          _EarningRow(
            label: '💰 Mancia',
            amount: order.tipAmount,
            isBonus: true,
          ),
      ],
    );
  }

  Widget _buildTotal() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'TOTALE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        Text(
          '€${order.totalEarning.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.greenAccent,
          ),
        ),
      ],
    );
  }

  bool _shouldShowActions() {
    return order.status == OrderStatus.pending ||
           order.status == OrderStatus.accepted ||
           order.status == OrderStatus.pickedUp;
  }

  Widget _buildActions(BuildContext context) {
    switch (order.status) {
      case OrderStatus.pending:
        return _ActionButton(
          label: 'ACCETTA ORDINE',
          icon: Icons.check_circle,
          color: Colors.green,
          onPressed: onAccept,
        );
      case OrderStatus.accepted:
        return _ActionButton(
          label: 'HO RITIRATO',
          icon: Icons.shopping_bag,
          color: Colors.blue,
          onPressed: onPickup,
        );
      case OrderStatus.pickedUp:
        return _ActionButton(
          label: 'CONSEGNATO',
          icon: Icons.delivery_dining,
          color: Colors.orange,
          onPressed: onDeliver,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _getStatusText() {
    switch (order.status) {
      case OrderStatus.pending:
        return 'In attesa di accettazione';
      case OrderStatus.accepted:
        return 'Vai al ristorante';
      case OrderStatus.pickedUp:
        return 'In consegna';
      case OrderStatus.delivered:
        return 'Completato';
      case OrderStatus.cancelled:
        return 'Annullato';
    }
  }

  Color _getStatusColor() {
    switch (order.status) {
      case OrderStatus.pending:
        return Colors.amber;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.pickedUp:
        return Colors.orange;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}

/// Badge Rush Hour
class _RushBadge extends StatelessWidget {
  const _RushBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔥', style: TextStyle(fontSize: 12)),
          SizedBox(width: 4),
          Text(
            '2X',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Riga singola breakdown guadagno
class _EarningRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBonus;

  const _EarningRow({
    required this.label,
    required this.amount,
    this.isBonus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBonus ? Colors.greenAccent.withOpacity(0.8) : Colors.white60,
              fontSize: 13,
            ),
          ),
          Text(
            '+€${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isBonus ? Colors.greenAccent : Colors.white70,
              fontWeight: isBonus ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip informativo
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white60),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottone azione
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
