import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/market_order.dart';
import '../../../services/market_orders_service.dart';
import '../../../theme/tokens.dart';

class MarketOrderCard extends StatelessWidget {
  final MarketOrder order;

  const MarketOrderCard({super.key, required this.order});

  Color get _statusColor {
    switch (order.status) {
      case MarketOrderStatus.pending:
        return AppColors.routeBlue;
      case MarketOrderStatus.accepted:
        return AppColors.turboOrange;
      case MarketOrderStatus.delivering:
        return AppColors.bonusPurple;
      case MarketOrderStatus.delivered:
        return AppColors.earningsGreen;
      case MarketOrderStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${order.productName} x${order.quantity}',
                  style: GoogleFonts.inter(fontSize: 8, color: Colors.white54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Flexible(
            flex: 0,
            child: Text(
              '\u20AC${order.totalPrice.toStringAsFixed(2)}',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.earningsGreen),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            flex: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                order.statusLabel,
                style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.w600, color: _statusColor),
              ),
            ),
          ),
          const SizedBox(width: 3),
          if (order.isActive) _nextStepButton(context),
        ],
      ),
    );
  }

  Widget _nextStepButton(BuildContext context) {
    final IconData icon;
    final MarketOrderStatus nextStatus;

    switch (order.status) {
      case MarketOrderStatus.pending:
        icon = Icons.check;
        nextStatus = MarketOrderStatus.accepted;
        break;
      case MarketOrderStatus.accepted:
        icon = Icons.delivery_dining;
        nextStatus = MarketOrderStatus.delivering;
        break;
      case MarketOrderStatus.delivering:
        icon = Icons.done_all;
        nextStatus = MarketOrderStatus.delivered;
        break;
      default:
        return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () async {
        if (nextStatus == MarketOrderStatus.delivered) {
          await MarketOrdersService.completeMarketOrder(order.id);
        } else {
          await MarketOrdersService.updateMarketOrderStatus(order.id, nextStatus);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ordine ${nextStatus.name}')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.earningsGreen.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 12, color: AppColors.earningsGreen),
      ),
    );
  }
}
