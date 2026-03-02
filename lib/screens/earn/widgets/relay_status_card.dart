import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/order_relay.dart';
import '../../../providers/order_relay_provider.dart';
import '../../../providers/contacts_provider.dart';
import '../../../theme/tokens.dart';
import 'dealer_picker_sheet.dart';
import 'fee_breakdown_sheet.dart';
import '../../../services/order_relay_service.dart';

/// Compact card showing relay status for an order.
/// Embed this inside the active order card / delivery screen.
class RelayStatusCard extends ConsumerWidget {
  final String orderId;
  final String? preAssignedDealerId;

  const RelayStatusCard({
    super.key,
    required this.orderId,
    this.preAssignedDealerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relayAsync = ref.watch(orderRelayProvider(orderId));

    return relayAsync.when(
      data: (relay) {
        if (relay == null) {
          return _buildNoRelay(context);
        }
        return _buildRelayStatus(context, ref, relay);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNoRelay(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        children: [
          Icon(Icons.store_mall_directory_outlined,
              color: Colors.grey.shade500, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nessun dealer assegnato',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          _ActionChip(
            label: 'Assegna',
            icon: Icons.add,
            color: AppColors.earningsGreen,
            onTap: () => _pickDealer(context),
          ),
        ],
      ),
    );
  }

  Widget _buildRelayStatus(BuildContext context, WidgetRef ref, OrderRelay relay) {
    // Look up dealer name from contacts
    final contactsAsync = ref.watch(contactsStreamProvider);
    final dealerName = contactsAsync.whenOrNull(
      data: (contacts) {
        final match = contacts.where((c) => c.id == relay.dealerContactId);
        return match.isNotEmpty ? match.first.name : null;
      },
    );
    final dealerPhone = contactsAsync.whenOrNull(
      data: (contacts) {
        final match = contacts.where((c) => c.id == relay.dealerContactId);
        return match.isNotEmpty ? match.first.phone : null;
      },
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor(relay.status).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dealer name + status badge
          Row(
            children: [
              Icon(Icons.store, color: _statusColor(relay.status), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dealerName ?? 'Dealer',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              _StatusBadge(status: relay.status),
            ],
          ),
          const SizedBox(height: 10),
          // Progress dots
          _ProgressDots(status: relay.status),
          const SizedBox(height: 10),
          // Actions row
          Row(
            children: [
              if (relay.canCancel)
                _ActionChip(
                  label: 'Cambia',
                  icon: Icons.swap_horiz,
                  color: AppColors.routeBlue,
                  onTap: () => _pickDealer(context),
                ),
              if (dealerPhone != null) ...[
                const SizedBox(width: 8),
                _ActionChip(
                  label: 'Chiama',
                  icon: Icons.phone,
                  color: AppColors.earningsGreen,
                  onTap: () => _callDealer(dealerPhone),
                ),
              ],
              const Spacer(),
              if (relay.isPaid) ...[
                _ActionChip(
                  label: 'Dettagli Fee',
                  icon: Icons.receipt_long,
                  color: AppColors.statsGold,
                  onTap: () => showFeeBreakdownSheet(context, orderId),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.earningsGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.earningsGreen, size: 14),
                      const SizedBox(width: 4),
                      Text('Pagato',
                          style: GoogleFonts.inter(
                              color: AppColors.earningsGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              if (relay.estimatedAmount != null && !relay.isPaid)
                Text(
                  '€${relay.estimatedAmount!.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDealer(BuildContext context) async {
    final dealer = await showDealerPickerSheet(context);
    if (dealer != null) {
      await OrderRelayService.createRelay(
        orderId: orderId,
        dealerContactId: dealer.id,
      );
    }
  }

  void _callDealer(String phone) {
    launchUrl(Uri.parse('tel:$phone'));
  }

  Color _statusColor(OrderRelayStatus status) {
    switch (status) {
      case OrderRelayStatus.pending:
        return AppColors.statsGold;
      case OrderRelayStatus.sent:
        return AppColors.routeBlue;
      case OrderRelayStatus.confirmed:
      case OrderRelayStatus.preparing:
        return AppColors.turboOrange;
      case OrderRelayStatus.ready:
      case OrderRelayStatus.pickedUp:
        return AppColors.earningsGreen;
      case OrderRelayStatus.cancelled:
        return AppColors.urgentRed;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderRelayStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case OrderRelayStatus.pending:
        return AppColors.statsGold;
      case OrderRelayStatus.sent:
        return AppColors.routeBlue;
      case OrderRelayStatus.confirmed:
      case OrderRelayStatus.preparing:
        return AppColors.turboOrange;
      case OrderRelayStatus.ready:
      case OrderRelayStatus.pickedUp:
        return AppColors.earningsGreen;
      case OrderRelayStatus.cancelled:
        return AppColors.urgentRed;
    }
  }

  String get _label {
    switch (status) {
      case OrderRelayStatus.pending:
        return 'In attesa';
      case OrderRelayStatus.sent:
        return 'Inviato';
      case OrderRelayStatus.confirmed:
        return 'Confermato';
      case OrderRelayStatus.preparing:
        return 'Preparazione';
      case OrderRelayStatus.ready:
        return 'Pronto';
      case OrderRelayStatus.pickedUp:
        return 'Ritirato';
      case OrderRelayStatus.cancelled:
        return 'Annullato';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label,
        style: GoogleFonts.inter(
            color: _color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final OrderRelayStatus status;
  const _ProgressDots({required this.status});

  int get _activeIndex {
    switch (status) {
      case OrderRelayStatus.pending:
        return 0;
      case OrderRelayStatus.sent:
        return 1;
      case OrderRelayStatus.confirmed:
      case OrderRelayStatus.preparing:
        return 2;
      case OrderRelayStatus.ready:
      case OrderRelayStatus.pickedUp:
        return 3;
      case OrderRelayStatus.cancelled:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['Inviato', 'Confermato', 'Preparazione', 'Pronto'];
    return Row(
      children: List.generate(4, (i) {
        final isActive = i <= _activeIndex;
        final isCurrent = i == _activeIndex;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i <= _activeIndex
                            ? AppColors.earningsGreen
                            : const Color(0xFF333333),
                      ),
                    ),
                  Container(
                    width: isCurrent ? 10 : 8,
                    height: isCurrent ? 10 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppColors.earningsGreen
                          : const Color(0xFF333333),
                    ),
                  ),
                  if (i < 3)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i < _activeIndex
                            ? AppColors.earningsGreen
                            : const Color(0xFF333333),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                style: TextStyle(
                  color: isActive ? Colors.white70 : Colors.grey.shade700,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.inter(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
