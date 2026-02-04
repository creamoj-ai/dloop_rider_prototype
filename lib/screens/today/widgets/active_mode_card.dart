import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';
import '../../../providers/earnings_provider.dart';
import '../../../services/rush_hour_service.dart';

/// Dati ordine disponibile
class AvailableOrder {
  final String id;
  final String restaurantName;
  final String restaurantAddress;
  final String customerAddress;
  final double distanceKm;
  final String? orderNotes;
  final bool isUrgent; // Ordine prioritario (🔥)

  const AvailableOrder({
    required this.id,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.customerAddress,
    required this.distanceKm,
    this.orderNotes,
    this.isUrgent = false,
  });

  /// Guadagno base (€1.50/km)
  double get baseEarning => distanceKm * 1.50;

  /// Guadagno con rush hour
  double get totalEarning => baseEarning * RushHourService.getCurrentMultiplier();

  /// Genera lista di ordini random
  static List<AvailableOrder> generateList(int count) {
    final random = Random();
    final orders = <AvailableOrder>[];

    const restaurants = [
      ('Pizzeria Da Mario', 'Via Torino 25'),
      ('Sushi Zen', 'Corso Italia 12'),
      ('Trattoria Nonna', 'Via Dante 8'),
      ('Burger King', 'Piazza Duomo 3'),
      ("McDonald's", 'Via Montenapoleone 15'),
      ('Poke House', 'Corso Buenos Aires 88'),
      ('Rossopomodoro', 'Via Brera 22'),
      ('La Piadineria', 'Via Paolo Sarpi 44'),
      ('KFC', 'Viale Papiniano 10'),
      ('Spontini', 'Corso Sempione 5'),
    ];

    const customerAddresses = [
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

    const notes = [
      null,
      'Citofono rotto, chiamare',
      'Consegnare al portiere',
      'Piano 3, scala B',
      'Suonare 2 volte',
      null,
      'Lasciare fuori dalla porta',
      null,
    ];

    // Usati per evitare duplicati
    final usedRestaurants = <int>{};

    for (int i = 0; i < count; i++) {
      int restaurantIdx;
      do {
        restaurantIdx = random.nextInt(restaurants.length);
      } while (usedRestaurants.contains(restaurantIdx) && usedRestaurants.length < restaurants.length);
      usedRestaurants.add(restaurantIdx);

      final restaurant = restaurants[restaurantIdx];
      final distance = 0.8 + random.nextDouble() * 3.5; // 0.8 - 4.3 km

      orders.add(AvailableOrder(
        id: 'order_${DateTime.now().millisecondsSinceEpoch}_$i',
        restaurantName: restaurant.$1,
        restaurantAddress: restaurant.$2,
        customerAddress: customerAddresses[random.nextInt(customerAddresses.length)],
        distanceKm: double.parse(distance.toStringAsFixed(1)),
        orderNotes: notes[random.nextInt(notes.length)],
        isUrgent: i == 0 && random.nextBool(), // Il primo potrebbe essere urgente
      ));
    }

    // Ordina per distanza (più vicini prima)
    orders.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return orders;
  }
}

class ActiveModeCard extends ConsumerStatefulWidget {
  const ActiveModeCard({super.key});

  @override
  ConsumerState<ActiveModeCard> createState() => _ActiveModeCardState();
}

class _ActiveModeCardState extends ConsumerState<ActiveModeCard> {
  // Lista ordini disponibili
  late List<AvailableOrder> _availableOrders;

  @override
  void initState() {
    super.initState();
    _availableOrders = AvailableOrder.generateList(4); // 4 ordini iniziali
  }

  void _refreshOrders() {
    setState(() {
      _availableOrders = AvailableOrder.generateList(3 + Random().nextInt(3)); // 3-5 ordini
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final earnings = ref.watch(earningsProvider);
    final target = earnings.dailyTarget;
    final isRushHour = RushHourService.isRushHourNow();

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
          // Header con titolo e refresh
          _buildHeader(cs, isRushHour),

          // Divider
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),

          // Lista ordini
          _buildOrdersList(cs, isRushHour),

          // Divider
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

  /// Header con conteggio ordini e refresh
  Widget _buildHeader(ColorScheme cs, bool isRushHour) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Row(
        children: [
          // Icona ordini
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

          // Titolo e conteggio
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
                  '${_availableOrders.length} disponibili',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Rush hour badge
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
                  const Icon(
                    Icons.local_fire_department,
                    size: 14,
                    color: AppColors.earningsGreen,
                  ),
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

          // Refresh button
          IconButton(
            onPressed: _refreshOrders,
            icon: Icon(
              Icons.refresh,
              color: cs.onSurfaceVariant,
              size: 22,
            ),
            tooltip: 'Aggiorna ordini',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// Lista ordini scrollabile
  Widget _buildOrdersList(ColorScheme cs, bool isRushHour) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _availableOrders.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: cs.outlineVariant.withValues(alpha: 0.2),
        indent: Spacing.lg,
        endIndent: Spacing.lg,
      ),
      itemBuilder: (context, index) {
        final order = _availableOrders[index];
        return _buildOrderRow(cs, order, isRushHour, index == 0);
      },
    );
  }

  /// Singola riga ordine
  Widget _buildOrderRow(ColorScheme cs, AvailableOrder order, bool isRushHour, bool isFirst) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicatore urgente o normale
          Container(
            width: 4,
            height: 48,
            margin: const EdgeInsets.only(right: Spacing.md),
            decoration: BoxDecoration(
              color: order.isUrgent
                  ? AppColors.turboOrange
                  : (isFirst ? AppColors.earningsGreen : cs.outlineVariant),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Info ordine
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome ristorante con badge urgente
                Row(
                  children: [
                    if (order.isUrgent) ...[
                      const Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: AppColors.turboOrange,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        order.restaurantName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Indirizzo e distanza
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

          // Guadagno e pulsante
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Guadagno
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

              // Pulsante ACCETTA
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () => _acceptOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: order.isUrgent
                        ? AppColors.turboOrange
                        : AppColors.earningsGreen,
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

  /// Accetta ordine e naviga
  void _acceptOrder(AvailableOrder order) {
    context.push('/today/delivery', extra: {
      'restaurantName': order.restaurantName,
      'restaurantAddress': order.restaurantAddress,
      'customerAddress': order.customerAddress,
      'distanceKm': order.distanceKm,
      'orderNotes': order.orderNotes,
    });

    // Rimuovi l'ordine accettato e rigenera la lista
    setState(() {
      _availableOrders.removeWhere((o) => o.id == order.id);
      // Se restano pochi ordini, aggiungine di nuovi
      if (_availableOrders.length < 2) {
        _availableOrders = AvailableOrder.generateList(3 + Random().nextInt(3));
      }
    });
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
                Icon(
                  Icons.flag_outlined,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
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
