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
    final popupHeight = screenHeight * 0.65; // 65% dello schermo

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
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  height: popupHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A1A1E),
                        const Color(0xFF0D0D0F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.earningsGreen.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.earningsGreen.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header con glow
                      _buildHeader(),

                      // Importo principale
                      Expanded(
                        child: _buildMainContent(),
                      ),

                      // CTA Network
                      _buildNetworkCTA(context),

                      const SizedBox(height: 20),
                    ],
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
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.earningsGreen.withOpacity(0.2),
            AppColors.earningsGreen.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          // Icona con glow
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.earningsGreen.withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.earningsGreen.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.celebration,
              size: 36,
              color: AppColors.earningsGreen,
            ),
          ),
          const SizedBox(height: 12),
          // Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isRushBonus)
                _buildBadge('🔥 RUSH 2X', AppColors.turboOrange),
              if (widget.isRushBonus && widget.hasTip)
                const SizedBox(width: 8),
              if (widget.hasTip)
                _buildBadge('💰 +TIP', AppColors.statsGold),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label - guadagno dal network
          Text(
            'GUADAGNO DAL TUO NETWORK',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 1.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Importo grande con shimmer - wrapped in FittedBox
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [
                        AppColors.earningsGreen,
                        Colors.white,
                        AppColors.earningsGreen,
                      ],
                      stops: [
                        _shimmerController.value - 0.3,
                        _shimmerController.value,
                        _shimmerController.value + 0.3,
                      ].map((s) => s.clamp(0.0, 1.0)).toList(),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: Text(
                    '+€${widget.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Fonte - network member
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.source,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Frase motivazionale
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _motivationalPhrase,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.statsGold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkCTA(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Divider decorativo
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.routeBlue.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // CTA Text
          Text(
            _networkCTA,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Bottone Network
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _goToNetwork(context),
              icon: const Icon(Icons.people_alt, size: 18),
              label: Flexible(
                child: Text(
                  'VAI AL TUO NETWORK',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.routeBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Link skip
          TextButton(
            onPressed: _dismiss,
            child: Text(
              'Continua a consegnare',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
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
