import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../theme/tokens.dart';

/// Frasi motivazionali per spingere il rider a espandere il network
final List<String> _motivationalPhrases = [
  'Stai costruendo il tuo impero! 🚀',
  'Ogni consegna è un mattone del tuo successo! 🧱',
  'Il tuo network cresce con te! 🌱',
  'Sei sulla strada giusta! 💪',
  'La tua reputazione parla per te! ⭐',
  'I grandi guadagni iniziano così! 📈',
  'Continua così, campione! 🏆',
];

/// Frasi CTA per espandere il network
final List<String> _networkCTAPhrases = [
  'Invita un amico e guadagna +€10!',
  'Espandi il tuo network, moltiplica i guadagni!',
  'Più contatti = Più guadagni passivi!',
  'Costruisci la tua rete di successo!',
];

/// Notifica popup a schermo grande per nuovo incasso
class EarningCelebrationPopup extends StatefulWidget {
  final double amount;
  final String source;
  final bool hasTip;
  final bool isRushBonus;
  final double tipAmount;
  final VoidCallback onDismiss;

  const EarningCelebrationPopup({
    super.key,
    required this.amount,
    required this.source,
    this.hasTip = false,
    this.isRushBonus = false,
    this.tipAmount = 0,
    required this.onDismiss,
  });

  @override
  State<EarningCelebrationPopup> createState() => _EarningCelebrationPopupState();
}

class _EarningCelebrationPopupState extends State<EarningCelebrationPopup>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  late String _motivationalPhrase;
  late String _networkCTA;

  @override
  void initState() {
    super.initState();

    // Seleziona frasi random
    final random = Random();
    _motivationalPhrase = _motivationalPhrases[random.nextInt(_motivationalPhrases.length)];
    _networkCTA = _networkCTAPhrases[random.nextInt(_networkCTAPhrases.length)];

    // Fade controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Scale controller
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Shimmer controller
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Start animations
    _fadeController.forward();
    _scaleController.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _fadeController.reverse();
    widget.onDismiss();
  }

  void _goToNetwork(BuildContext context) {
    _dismiss();
    context.push('/money/network');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.7;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _dismiss,
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                onTap: () {}, // Blocca tap passthrough
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1A1E), Color(0xFF0D0D0F)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.earningsGreen.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(color: AppColors.earningsGreen.withOpacity(0.3), blurRadius: 30, spreadRadius: 3),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        _buildMainContent(),
                        _buildNetworkCTA(context),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.earningsGreen.withOpacity(0.2), AppColors.earningsGreen.withOpacity(0.05)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.earningsGreen.withOpacity(0.2),
              boxShadow: [BoxShadow(color: AppColors.earningsGreen.withOpacity(0.4), blurRadius: 16, spreadRadius: 1)],
            ),
            child: const Icon(Icons.celebration, size: 28, color: AppColors.earningsGreen),
          ),
          if (widget.isRushBonus || widget.hasTip) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isRushBonus) _buildBadge('🔥 RUSH', AppColors.turboOrange),
                if (widget.isRushBonus && widget.hasTip) const SizedBox(width: 6),
                if (widget.hasTip) _buildBadge('💰 TIP', AppColors.statsGold),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'GUADAGNO DAL NETWORK',
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [AppColors.earningsGreen, Colors.white, AppColors.earningsGreen],
                      stops: [
                        (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                        _shimmerController.value.clamp(0.0, 1.0),
                        (_shimmerController.value + 0.3).clamp(0.0, 1.0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: Text(
                    '+€${widget.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.source,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _motivationalPhrase,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.statsGold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkCTA(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.transparent, AppColors.routeBlue.withOpacity(0.4), Colors.transparent]),
            ),
          ),
          Text(
            _networkCTA,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _goToNetwork(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.routeBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_alt, size: 14),
                  const SizedBox(width: 6),
                  Text('VAI AL NETWORK', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _dismiss,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
            child: Text('Continua', style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
          ),
        ],
      ),
    );
  }
}

/// Controller per gestire le notifiche di incasso
class EarningNotificationController extends ChangeNotifier {
  final List<EarningNotificationData> _queue = [];

  List<EarningNotificationData> get notifications => List.unmodifiable(_queue);

  void show({
    required double amount,
    required String source,
    bool hasTip = false,
    bool isRushBonus = false,
    double tipAmount = 0,
  }) {
    _queue.add(EarningNotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      source: source,
      hasTip: hasTip,
      isRushBonus: isRushBonus,
      tipAmount: tipAmount,
    ));
    notifyListeners();
  }

  void dismiss(String id) {
    _queue.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clear() {
    _queue.clear();
    notifyListeners();
  }
}

class EarningNotificationData {
  final String id;
  final double amount;
  final String source;
  final bool hasTip;
  final bool isRushBonus;
  final double tipAmount;

  EarningNotificationData({
    required this.id,
    required this.amount,
    required this.source,
    this.hasTip = false,
    this.isRushBonus = false,
    this.tipAmount = 0,
  });
}

/// Overlay per mostrare le notifiche celebration
class EarningNotificationOverlay extends StatelessWidget {
  final EarningNotificationController controller;
  final Widget child;

  const EarningNotificationOverlay({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.notifications.isEmpty) {
              return const SizedBox.shrink();
            }
            // Mostra solo la prima notifica (queue)
            final notification = controller.notifications.first;
            return EarningCelebrationPopup(
              key: ValueKey(notification.id),
              amount: notification.amount,
              source: notification.source,
              hasTip: notification.hasTip,
              isRushBonus: notification.isRushBonus,
              tipAmount: notification.tipAmount,
              onDismiss: () => controller.dismiss(notification.id),
            );
          },
        ),
      ],
    );
  }
}
