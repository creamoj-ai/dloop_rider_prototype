import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';
import '../../../providers/earnings_provider.dart';
import '../../../services/rush_hour_service.dart';

/// Stati dell'ordine
enum OrderState {
  newOrder,    // Nuovo ordine disponibile
  toPickup,    // Da ritirare al ristorante
  delivering,  // In consegna al cliente
}

/// Dati ordine random
class _RandomOrder {
  final String restaurantName;
  final String customerAddress;
  final double distanceKm;

  const _RandomOrder({
    required this.restaurantName,
    required this.customerAddress,
    required this.distanceKm,
  });

  /// Guadagno base (€1.50/km)
  double get baseEarning => distanceKm * 1.50;

  /// Guadagno con rush hour
  double get totalEarning => baseEarning * RushHourService.getCurrentMultiplier();

  /// Genera ordine random
  static _RandomOrder generate() {
    final random = Random();

    const restaurants = [
      'Pizzeria Da Mario',
      'Sushi Zen',
      'Trattoria Nonna',
      'Burger King',
      "McDonald's",
      'Poke House',
      'Rossopomodoro',
      'La Piadineria',
      'KFC',
      'Spontini',
    ];

    const addresses = [
      'Via Roma 15',
      'Corso Italia 88',
      'Via Torino 12',
      'Via Dante 23',
      'Corso Buenos Aires 45',
      'Via Montenapoleone 8',
      'Piazza Duomo 1',
      'Via Brera 30',
      'Corso Sempione 76',
      'Via Paolo Sarpi 55',
      'Viale Papiniano 42',
      'Via Padova 118',
    ];

    // Distanza random tra 0.5 e 4.5 km
    final distance = 0.5 + random.nextDouble() * 4.0;

    return _RandomOrder(
      restaurantName: restaurants[random.nextInt(restaurants.length)],
      customerAddress: addresses[random.nextInt(addresses.length)],
      distanceKm: double.parse(distance.toStringAsFixed(1)),
    );
  }
}

class ActiveModeCard extends ConsumerStatefulWidget {
  const ActiveModeCard({super.key});

  @override
  ConsumerState<ActiveModeCard> createState() => _ActiveModeCardState();
}

class _ActiveModeCardState extends ConsumerState<ActiveModeCard> {
  // Ordine corrente (random)
  late _RandomOrder _currentOrder;
  // Stato corrente dell'ordine
  OrderState _orderState = OrderState.newOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = _RandomOrder.generate();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final earnings = ref.watch(earningsProvider);
    final target = earnings.dailyTarget;
    final isRushHour = RushHourService.isRushHourNow();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _chipColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChipsRow(isRushHour),
          const SizedBox(height: 20),
          _buildOrderContent(cs, isRushHour),
          const SizedBox(height: 16),
          _buildDailyTarget(cs, target),
          const SizedBox(height: 20),
          _buildCta(context),
        ],
      ),
    );
  }

  /// Chip label e colore in base allo stato
  String get _chipLabel {
    switch (_orderState) {
      case OrderState.newOrder:
        return 'NUOVO ORDINE';
      case OrderState.toPickup:
        return 'DA RITIRARE';
      case OrderState.delivering:
        return 'IN CONSEGNA';
    }
  }

  Color get _chipColor {
    switch (_orderState) {
      case OrderState.newOrder:
        return AppColors.earningsGreen;
      case OrderState.toPickup:
      case OrderState.delivering:
        return AppColors.turboOrange;
    }
  }

  /// Chips: stato ordine + (opzionale) 2X ATTIVO
  Widget _buildChipsRow(bool isRushHour) {
    return Row(
      children: [
        // Chip stato ordine
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _chipColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _chipLabel,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _chipColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
        // Chip 2X ATTIVO (solo in rush hour)
        if (isRushHour) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.earningsGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 14,
                  color: AppColors.earningsGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  '2X ATTIVO',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.earningsGreen,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Contenuto ordine con dati dinamici
  Widget _buildOrderContent(ColorScheme cs, bool isRushHour) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nome ristorante
        Text(
          _currentOrder.restaurantName,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        // Indirizzo cliente
        Text(
          '→ ${_currentOrder.customerAddress}',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        // Info: km + guadagno
        Row(
          children: [
            Icon(Icons.straighten, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              '${_currentOrder.distanceKm} km',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 20),
            Icon(Icons.euro, size: 14, color: AppColors.earningsGreen),
            const SizedBox(width: 4),
            // Prezzo con/senza rush hour
            if (isRushHour) ...[
              // Prezzo base barrato
              Text(
                '€ ${_currentOrder.baseEarning.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 6),
              // Prezzo 2x
              Text(
                '€ ${_currentOrder.totalEarning.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.earningsGreen,
                ),
              ),
            ] else ...[
              // Prezzo normale
              Text(
                '€ ${_currentOrder.baseEarning.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.earningsGreen,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Barra obiettivo giornaliero
  Widget _buildDailyTarget(ColorScheme cs, dynamic target) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '€ ${target.currentAmount.toStringAsFixed(0)} / € ${target.targetAmount.toStringAsFixed(0)} oggi',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
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
        const SizedBox(height: 8),
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

  /// Testo e icona del pulsante in base allo stato
  String get _ctaLabel {
    switch (_orderState) {
      case OrderState.newOrder:
        return 'ACCETTA E VAI';
      case OrderState.toPickup:
        return 'HO RITIRATO';
      case OrderState.delivering:
        return 'CONSEGNATO';
    }
  }

  IconData get _ctaIcon {
    switch (_orderState) {
      case OrderState.newOrder:
        return Icons.arrow_forward;
      case OrderState.toPickup:
      case OrderState.delivering:
        return Icons.check;
    }
  }

  /// Pulsante CTA
  Widget _buildCta(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () => _onCtaTap(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _chipColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _ctaLabel,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Icon(_ctaIcon, size: 18),
          ],
        ),
      ),
    );
  }

  /// Gestisce il tap sul CTA in base allo stato
  void _onCtaTap(BuildContext context) {
    switch (_orderState) {
      case OrderState.newOrder:
        // Accetta ordine → passa a "da ritirare"
        setState(() {
          _orderState = OrderState.toPickup;
        });
        _showSnackbar(context, 'Ordine accettato! Vai al ristorante', Icons.restaurant);
        break;

      case OrderState.toPickup:
        // Ritirato → passa a "in consegna"
        setState(() {
          _orderState = OrderState.delivering;
        });
        _showSnackbar(context, 'Ritirato! Consegna al cliente', Icons.delivery_dining);
        break;

      case OrderState.delivering:
        // Consegnato → completa ordine e genera nuovo
        _completeOrder(context);
        break;
    }
  }

  /// Completa l'ordine e genera uno nuovo
  void _completeOrder(BuildContext context) {
    final isRushHour = RushHourService.isRushHourNow();
    final earning = _currentOrder.totalEarning;

    // Aggiorna guadagni
    ref.read(earningsProvider.notifier).simulateCompletedOrder(
      restaurantName: _currentOrder.restaurantName,
      customerAddress: _currentOrder.customerAddress,
      distanceKm: _currentOrder.distanceKm,
      tipAmount: 0,
    );

    // Feedback con importo
    final message = isRushHour
        ? '+€ ${earning.toStringAsFixed(2)} guadagnati! (2x rush hour)'
        : '+€ ${earning.toStringAsFixed(2)} guadagnati!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isRushHour ? Icons.local_fire_department : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              message,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.earningsGreen,
        duration: const Duration(seconds: 2),
      ),
    );

    // Reset: nuovo ordine random
    setState(() {
      _orderState = OrderState.newOrder;
      _currentOrder = _RandomOrder.generate();
    });
  }

  /// Mostra snackbar informativa
  void _showSnackbar(BuildContext context, String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              message,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.turboOrange,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
