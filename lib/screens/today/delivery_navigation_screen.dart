import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/tokens.dart';
import '../../providers/earnings_provider.dart';
import '../../services/rush_hour_service.dart';

/// Stati della navigazione consegna
enum DeliveryPhase {
  toRestaurant,   // In viaggio verso ristorante
  atRestaurant,   // Arrivato al ristorante
  toCustomer,     // In viaggio verso cliente
  atCustomer,     // Arrivato dal cliente
}

/// Schermata navigazione consegna (EARN-03)
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
  DeliveryPhase _phase = DeliveryPhase.toRestaurant;

  // Mock data per ordine
  final List<String> _orderItems = [
    '2x Pizza Margherita',
    '1x Coca Cola 33cl',
    '1x Tiramisù',
  ];

  double get _baseEarning => widget.distanceKm * 1.50;
  double get _totalEarning => _baseEarning * RushHourService.getCurrentMultiplier();
  bool get _isRushHour => RushHourService.isRushHourNow();

  // Tempo stimato in base alla fase
  int get _estimatedMinutes {
    switch (_phase) {
      case DeliveryPhase.toRestaurant:
        return (widget.distanceKm * 2.5).round(); // ~2.5 min/km
      case DeliveryPhase.atRestaurant:
        return 3; // tempo ritiro
      case DeliveryPhase.toCustomer:
        return (widget.distanceKm * 3).round(); // ~3 min/km
      case DeliveryPhase.atCustomer:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(cs),
            // Mappa (placeholder)
            Expanded(
              flex: 3,
              child: _buildMapPlaceholder(cs),
            ),
            // Info card
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusBadge(cs),
                      const SizedBox(height: Spacing.lg),
                      _buildDestinationCard(cs),
                      const SizedBox(height: Spacing.lg),
                      _buildOrderDetails(cs),
                      if (widget.orderNotes != null && widget.orderNotes!.isNotEmpty) ...[
                        const SizedBox(height: Spacing.lg),
                        _buildNotes(cs),
                      ],
                      const SizedBox(height: Spacing.xl),
                      _buildActionButtons(cs),
                      const SizedBox(height: Spacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header con back button e info ordine
  Widget _buildHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _showExitConfirmation(cs),
            color: cs.onSurface,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ordine in corso',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  '${widget.distanceKm} km • €${_totalEarning.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Badge rush hour
          if (_isRushHour)
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

  /// Placeholder mappa con icone percorso
  Widget _buildMapPlaceholder(ColorScheme cs) {
    return Container(
      width: double.infinity,
      color: cs.surfaceContainerLowest,
      child: Stack(
        children: [
          // Background griglia
          CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(cs.outlineVariant.withValues(alpha: 0.1)),
          ),
          // Percorso stilizzato
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Posizione attuale
                _buildMapMarker(
                  cs,
                  Icons.my_location,
                  AppColors.routeBlue,
                  'Tu',
                  isActive: _phase == DeliveryPhase.toRestaurant || _phase == DeliveryPhase.toCustomer,
                ),
                _buildRouteLine(cs, isActive: _phase == DeliveryPhase.toRestaurant),
                // Ristorante
                _buildMapMarker(
                  cs,
                  Icons.restaurant,
                  AppColors.turboOrange,
                  widget.restaurantName,
                  isActive: _phase == DeliveryPhase.toRestaurant || _phase == DeliveryPhase.atRestaurant,
                  isCompleted: _phase == DeliveryPhase.toCustomer || _phase == DeliveryPhase.atCustomer,
                ),
                _buildRouteLine(cs, isActive: _phase == DeliveryPhase.toCustomer),
                // Cliente
                _buildMapMarker(
                  cs,
                  Icons.home,
                  AppColors.earningsGreen,
                  widget.customerAddress,
                  isActive: _phase == DeliveryPhase.toCustomer || _phase == DeliveryPhase.atCustomer,
                ),
              ],
            ),
          ),
          // Info overlay
          Positioned(
            top: Spacing.lg,
            left: Spacing.lg,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    '$_estimatedMinutes min',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapMarker(ColorScheme cs, IconData icon, Color color, String label, {bool isActive = false, bool isCompleted = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.earningsGreen.withValues(alpha: 0.2)
                : isActive
                    ? color.withValues(alpha: 0.2)
                    : cs.outlineVariant.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isCompleted ? AppColors.earningsGreen : isActive ? color : cs.outlineVariant,
              width: 2,
            ),
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isCompleted ? AppColors.earningsGreen : isActive ? color : cs.outlineVariant,
            size: 22,
          ),
        ),
        const SizedBox(width: Spacing.md),
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? cs.onSurface : cs.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteLine(ColorScheme cs, {bool isActive = false}) {
    return Container(
      width: 2,
      height: 30,
      margin: const EdgeInsets.only(left: 21),
      decoration: BoxDecoration(
        color: isActive ? AppColors.routeBlue : cs.outlineVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  /// Badge stato corrente
  Widget _buildStatusBadge(ColorScheme cs) {
    String label;
    Color color;
    IconData icon;

    switch (_phase) {
      case DeliveryPhase.toRestaurant:
        label = 'IN VIAGGIO VERSO RISTORANTE';
        color = AppColors.routeBlue;
        icon = Icons.directions_bike;
        break;
      case DeliveryPhase.atRestaurant:
        label = 'RITIRA L\'ORDINE';
        color = AppColors.turboOrange;
        icon = Icons.restaurant;
        break;
      case DeliveryPhase.toCustomer:
        label = 'IN CONSEGNA';
        color = AppColors.turboOrange;
        icon = Icons.delivery_dining;
        break;
      case DeliveryPhase.atCustomer:
        label = 'CONSEGNA AL CLIENTE';
        color = AppColors.earningsGreen;
        icon = Icons.home;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm + 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Card destinazione corrente
  Widget _buildDestinationCard(ColorScheme cs) {
    final isRestaurantPhase = _phase == DeliveryPhase.toRestaurant || _phase == DeliveryPhase.atRestaurant;
    final title = isRestaurantPhase ? widget.restaurantName : 'Cliente';
    final address = isRestaurantPhase ? widget.restaurantAddress : widget.customerAddress;
    final icon = isRestaurantPhase ? Icons.restaurant : Icons.home;
    final color = isRestaurantPhase ? AppColors.turboOrange : AppColors.earningsGreen;

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacing.sm + 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: Spacing.md + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      address,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          // Pulsanti azione rapida
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  cs,
                  Icons.navigation,
                  'Naviga',
                  AppColors.routeBlue,
                  () => _openNavigation(address),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _buildQuickAction(
                  cs,
                  Icons.phone,
                  'Chiama',
                  AppColors.earningsGreen,
                  () => _makeCall(isRestaurantPhase ? '+39 02 1234567' : '+39 333 1234567'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(ColorScheme cs, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.sm + 2),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Radii.sm + 2),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: Spacing.sm),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dettagli ordine
  Widget _buildOrderDetails(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacing.sm + 2),
              Text(
                'Dettagli ordine',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          ..._orderItems.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: Spacing.sm + 2),
                Text(
                  item,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// Note ordine
  Widget _buildNotes(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: AppColors.statsGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.statsGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.statsGold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Note cliente',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statsGold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.orderNotes!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pulsanti azione principali
  Widget _buildActionButtons(ColorScheme cs) {
    String primaryLabel;
    Color primaryColor;
    IconData primaryIcon;
    VoidCallback primaryAction;

    switch (_phase) {
      case DeliveryPhase.toRestaurant:
        primaryLabel = 'SONO ARRIVATO';
        primaryColor = AppColors.turboOrange;
        primaryIcon = Icons.location_on;
        primaryAction = () => setState(() => _phase = DeliveryPhase.atRestaurant);
        break;
      case DeliveryPhase.atRestaurant:
        primaryLabel = 'ORDINE RITIRATO';
        primaryColor = AppColors.turboOrange;
        primaryIcon = Icons.check_circle;
        primaryAction = () => setState(() => _phase = DeliveryPhase.toCustomer);
        break;
      case DeliveryPhase.toCustomer:
        primaryLabel = 'SONO ARRIVATO';
        primaryColor = AppColors.earningsGreen;
        primaryIcon = Icons.location_on;
        primaryAction = () => setState(() => _phase = DeliveryPhase.atCustomer);
        break;
      case DeliveryPhase.atCustomer:
        primaryLabel = 'CONSEGNATO';
        primaryColor = AppColors.earningsGreen;
        primaryIcon = Icons.check_circle;
        primaryAction = () => _completeDelivery();
        break;
    }

    return Column(
      children: [
        // Pulsante principale
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: primaryAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              elevation: Elevation.none,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(primaryIcon, size: 20),
                const SizedBox(width: Spacing.sm + 2),
                Text(
                  primaryLabel,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        // Pulsante problema
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: () => _showProblemSheet(cs),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.urgentRed,
              side: BorderSide(color: AppColors.urgentRed.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber, size: 18),
                const SizedBox(width: Spacing.sm),
                Text(
                  'Segnala problema',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Completa la consegna
  void _completeDelivery() {
    // Aggiorna guadagni
    ref.read(earningsProvider.notifier).simulateCompletedOrder(
      restaurantName: widget.restaurantName,
      customerAddress: widget.customerAddress,
      distanceKm: widget.distanceKm,
      tipAmount: 0,
    );

    // Feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isRushHour ? Icons.local_fire_department : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              '+€${_totalEarning.toStringAsFixed(2)} guadagnati!${_isRushHour ? ' (2x rush hour)' : ''}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.earningsGreen,
        duration: const Duration(seconds: 2),
      ),
    );

    // Torna alla schermata principale
    context.go('/today');
  }

  /// Apre navigazione esterna
  Future<void> _openNavigation(String address) async {
    final encodedAddress = Uri.encodeComponent('$address, Milano');
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Effettua chiamata
  Future<void> _makeCall(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  /// Conferma uscita
  void _showExitConfirmation(ColorScheme cs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text(
          'Annullare ordine?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        content: Text(
          'Se esci perderai questo ordine e potrebbe influire sulla tua valutazione.',
          style: GoogleFonts.inter(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continua', style: GoogleFonts.inter(color: AppColors.earningsGreen)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/today');
            },
            child: Text('Annulla ordine', style: GoogleFonts.inter(color: AppColors.urgentRed)),
          ),
        ],
      ),
    );
  }

  /// Sheet problemi
  void _showProblemSheet(ColorScheme cs) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Segnala problema',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            const SizedBox(height: 20),
            _problemOption(cs, Icons.store_mall_directory, 'Ristorante chiuso'),
            _problemOption(cs, Icons.timer_off, 'Attesa troppo lunga'),
            _problemOption(cs, Icons.no_food, 'Ordine non disponibile'),
            _problemOption(cs, Icons.person_off, 'Cliente non reperibile'),
            _problemOption(cs, Icons.wrong_location, 'Indirizzo errato'),
            _problemOption(cs, Icons.support_agent, 'Altro - Contatta supporto'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _problemOption(ColorScheme cs, IconData icon, String label) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Problema segnalato: $label'),
            backgroundColor: AppColors.turboOrange,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: cs.onSurfaceVariant),
            const SizedBox(width: 14),
            Text(label, style: GoogleFonts.inter(fontSize: 15, color: cs.onSurface)),
          ],
        ),
      ),
    );
  }
}

/// Painter per griglia mappa
class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
