import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/tokens.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/active_orders_provider.dart';
import '../../services/rush_hour_service.dart';

/// Schermata gestione ordini multitasking (EARN-03 v2)
class DeliveryNavigationScreen extends ConsumerStatefulWidget {
  final String restaurantName;
  final String restaurantAddress;
  final String customerAddress;
  final double distanceKm;
  final String? orderNotes;

  const DeliveryNavigationScreen({
    super.key,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.customerAddress,
    required this.distanceKm,
    this.orderNotes,
  });

  @override
  ConsumerState<DeliveryNavigationScreen> createState() => _DeliveryNavigationScreenState();
}

class _DeliveryNavigationScreenState extends ConsumerState<DeliveryNavigationScreen> {
  @override
  void initState() {
    super.initState();
    // Aggiungi l'ordine iniziale se non già presente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(activeOrdersProvider);
      final alreadyExists = state.orders.any((o) =>
        o.dealerName == widget.restaurantName &&
        o.customerAddress == widget.customerAddress
      );
      if (!alreadyExists) {
        ref.read(activeOrdersProvider.notifier).acceptOrder(
          ActiveOrder(
            id: 'order_${DateTime.now().millisecondsSinceEpoch}',
            dealerName: widget.restaurantName,
            dealerAddress: widget.restaurantAddress,
            customerAddress: widget.customerAddress,
            distanceKm: widget.distanceKm,
            orderNotes: widget.orderNotes,
            acceptedAt: DateTime.now(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ordersState = ref.watch(activeOrdersProvider);
    final isRushHour = RushHourService.isRushHourNow();

    // Filtra ordini non completati
    final activeOrders = ordersState.orders
        .where((o) => o.phase != OrderPhase.completed)
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: _buildAddOrderFab(cs, ordersState),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(cs, activeOrders, ordersState.totalEarning, isRushHour),
            // Lista ordini attivi
            Expanded(
              child: activeOrders.isEmpty
                  ? _buildEmptyState(cs)
                  : ListView.builder(
                      padding: const EdgeInsets.all(Spacing.lg),
                      itemCount: activeOrders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(cs, activeOrders[index], isRushHour);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header con info generali
  Widget _buildHeader(ColorScheme cs, List<ActiveOrder> activeOrders, double totalEarning, bool isRushHour) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _showExitConfirmation(cs, activeOrders.length),
            color: cs.onSurface,
          ),
          const SizedBox(width: Spacing.sm),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ordini attivi',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  '${activeOrders.length} ${activeOrders.length == 1 ? 'ordine' : 'ordini'} • €${totalEarning.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.earningsGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Rush hour badge
          if (isRushHour)
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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.earningsGreen,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Card singolo ordine
  Widget _buildOrderCard(ColorScheme cs, ActiveOrder order, bool isRushHour) {
    final phaseColor = _getPhaseColor(order.phase);
    final isAtLocation = order.phase == OrderPhase.atPickup || order.phase == OrderPhase.atCustomer;

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: phaseColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card con stato
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
            decoration: BoxDecoration(
              color: phaseColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.lg - 1)),
            ),
            child: Row(
              children: [
                // Icona stato
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: phaseColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPhaseIcon(order.phase),
                    size: 18,
                    color: phaseColor,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                // Label stato
                Expanded(
                  child: Text(
                    order.phaseLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: phaseColor,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Guadagno
                Text(
                  '€${order.totalEarning.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.earningsGreen,
                  ),
                ),
              ],
            ),
          ),
          // Contenuto card
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Destinazione corrente
                _buildDestinationRow(cs, order),
                const SizedBox(height: Spacing.md),
                // Note (se presenti e in fase ritiro/consegna)
                if (order.orderNotes != null && isAtLocation) ...[
                  _buildNotesRow(cs, order.orderNotes!),
                  const SizedBox(height: Spacing.md),
                ],
                // Azioni rapide
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        cs,
                        Icons.navigation,
                        'Naviga',
                        AppColors.routeBlue,
                        () => _openNavigation(_getCurrentAddress(order)),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: _buildQuickAction(
                        cs,
                        Icons.phone,
                        'Chiama',
                        AppColors.earningsGreen,
                        () => _makeCall('+39 333 1234567'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.lg),
                // Pulsante azione principale
                Row(
                  children: [
                    // Pulsante annulla (piccolo)
                    IconButton(
                      onPressed: () => _showCancelConfirmation(cs, order),
                      icon: const Icon(Icons.close),
                      color: AppColors.urgentRed,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.urgentRed.withValues(alpha: 0.1),
                      ),
                      tooltip: 'Annulla ordine',
                    ),
                    const SizedBox(width: Spacing.md),
                    // Pulsante azione principale
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _advanceOrder(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: phaseColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Radii.md),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getActionIcon(order.phase), size: 20),
                              const SizedBox(width: Spacing.sm),
                              Flexible(
                                child: Text(
                                  order.actionLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Riga destinazione
  Widget _buildDestinationRow(ColorScheme cs, ActiveOrder order) {
    final isPickupPhase = order.phase == OrderPhase.toPickup || order.phase == OrderPhase.atPickup;
    final icon = isPickupPhase ? Icons.store : Icons.home;
    final title = isPickupPhase ? order.dealerName : 'Cliente';
    final address = isPickupPhase ? order.dealerAddress : order.customerAddress;

    return Row(
      children: [
        Icon(icon, size: 20, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                address,
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
        // Distanza
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm + 2, vertical: Spacing.xs + 2),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Text(
            '${order.distanceKm} km',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  /// Note ordine
  Widget _buildNotesRow(ColorScheme cs, String notes) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.statsGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: AppColors.statsGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.statsGold),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              notes,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.statsGold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Azione rapida
  Widget _buildQuickAction(ColorScheme cs, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm + 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: Spacing.sm),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// FAB per aggiungere ordini
  Widget _buildAddOrderFab(ColorScheme cs, ActiveOrdersState state) {
    return FloatingActionButton.extended(
      onPressed: () => _showAvailableOrdersSheet(cs, state),
      backgroundColor: AppColors.earningsGreen,
      foregroundColor: Colors.white,
      icon: Badge(
        label: Text('${state.availableOrders.length}'),
        backgroundColor: AppColors.turboOrange,
        child: const Icon(Icons.add_shopping_cart, size: 22),
      ),
      label: Text(
        'AGGIUNGI',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Stato vuoto
  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: cs.outlineVariant),
          const SizedBox(height: Spacing.lg),
          Text(
            'Nessun ordine attivo',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Aggiungi ordini per iniziare',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          ElevatedButton.icon(
            onPressed: () {
              final state = ref.read(activeOrdersProvider);
              _showAvailableOrdersSheet(Theme.of(context).colorScheme, state);
            },
            icon: const Icon(Icons.add),
            label: const Text('AGGIUNGI ORDINE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.earningsGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Sheet ordini disponibili
  void _showAvailableOrdersSheet(ColorScheme cs, ActiveOrdersState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Consumer(
          builder: (context, ref, _) {
            final currentState = ref.watch(activeOrdersProvider);
            return Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: Spacing.md),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
                  child: Row(
                    children: [
                      const Icon(Icons.add_shopping_cart, color: AppColors.earningsGreen, size: 22),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ordini disponibili',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              '${currentState.availableOrders.length} nelle vicinanze',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref.read(activeOrdersProvider.notifier).refreshAvailableOrders(),
                        icon: Icon(Icons.refresh, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
                // Lista
                Expanded(
                  child: currentState.availableOrders.isEmpty
                      ? Center(
                          child: Text(
                            'Nessun ordine disponibile',
                            style: GoogleFonts.inter(color: cs.onSurfaceVariant),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(Spacing.lg),
                          itemCount: currentState.availableOrders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
                          itemBuilder: (_, index) {
                            final order = currentState.availableOrders[index];
                            return _buildAvailableOrderCard(cs, order);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Card ordine disponibile
  Widget _buildAvailableOrderCard(ColorScheme cs, ActiveOrder order) {
    final isRushHour = RushHourService.isRushHourNow();

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  order.dealerName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isRushHour) ...[
                Text(
                  '€${order.baseEarning.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                '€${order.totalEarning.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.earningsGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            '${order.dealerAddress} → ${order.customerAddress}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${order.distanceKm} km totali',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.md),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(activeOrdersProvider.notifier).acceptOrder(order);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${order.dealerName} aggiunto!'),
                    backgroundColor: AppColors.earningsGreen,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'ACCETTA ORDINE',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.earningsGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === HELPERS ===

  Color _getPhaseColor(OrderPhase phase) {
    switch (phase) {
      case OrderPhase.toPickup:
        return AppColors.routeBlue;
      case OrderPhase.atPickup:
        return AppColors.turboOrange;
      case OrderPhase.toCustomer:
        return AppColors.turboOrange;
      case OrderPhase.atCustomer:
        return AppColors.earningsGreen;
      case OrderPhase.completed:
        return AppColors.earningsGreen;
    }
  }

  IconData _getPhaseIcon(OrderPhase phase) {
    switch (phase) {
      case OrderPhase.toPickup:
        return Icons.directions_bike;
      case OrderPhase.atPickup:
        return Icons.store;
      case OrderPhase.toCustomer:
        return Icons.delivery_dining;
      case OrderPhase.atCustomer:
        return Icons.home;
      case OrderPhase.completed:
        return Icons.check_circle;
    }
  }

  IconData _getActionIcon(OrderPhase phase) {
    switch (phase) {
      case OrderPhase.toPickup:
      case OrderPhase.toCustomer:
        return Icons.location_on;
      case OrderPhase.atPickup:
      case OrderPhase.atCustomer:
        return Icons.check_circle;
      case OrderPhase.completed:
        return Icons.check_circle;
    }
  }

  String _getCurrentAddress(ActiveOrder order) {
    final isPickupPhase = order.phase == OrderPhase.toPickup || order.phase == OrderPhase.atPickup;
    return isPickupPhase ? order.dealerAddress : order.customerAddress;
  }

  void _advanceOrder(ActiveOrder order) {
    if (order.phase == OrderPhase.atCustomer) {
      // Completa ordine
      ref.read(earningsProvider.notifier).simulateCompletedOrder(
        restaurantName: order.dealerName,
        customerAddress: order.customerAddress,
        distanceKm: order.distanceKm,
        tipAmount: 0,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                '+€${order.totalEarning.toStringAsFixed(2)} guadagnati!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.earningsGreen,
          duration: const Duration(seconds: 2),
        ),
      );
      // Rimuovi dopo un attimo per mostrare il completamento
      Future.delayed(const Duration(milliseconds: 500), () {
        ref.read(activeOrdersProvider.notifier).removeCompletedOrder(order.id);
        // Se non ci sono più ordini, torna alla home
        final remaining = ref.read(activeOrdersProvider).orders
            .where((o) => o.phase != OrderPhase.completed)
            .length;
        if (remaining == 0) {
          context.go('/today');
        }
      });
    }
    ref.read(activeOrdersProvider.notifier).advanceOrder(order.id);
  }

  Future<void> _openNavigation(String address) async {
    final encodedAddress = Uri.encodeComponent('$address, Milano');
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showExitConfirmation(ColorScheme cs, int orderCount) {
    if (orderCount == 0) {
      context.go('/today');
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text(
          'Uscire dalla gestione ordini?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        content: Text(
          'Hai $orderCount ${orderCount == 1 ? 'ordine attivo' : 'ordini attivi'}. Puoi tornare in qualsiasi momento.',
          style: GoogleFonts.inter(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Resta', style: GoogleFonts.inter(color: AppColors.earningsGreen)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/today');
            },
            child: Text('Esci', style: GoogleFonts.inter(color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(ColorScheme cs, ActiveOrder order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text(
          'Annullare ordine?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        content: Text(
          'L\'ordine da ${order.dealerName} verrà rimesso tra quelli disponibili.',
          style: GoogleFonts.inter(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Mantieni', style: GoogleFonts.inter(color: AppColors.earningsGreen)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(activeOrdersProvider.notifier).cancelOrder(order.id);
            },
            child: Text('Annulla ordine', style: GoogleFonts.inter(color: AppColors.urgentRed)),
          ),
        ],
      ),
    );
  }
}
