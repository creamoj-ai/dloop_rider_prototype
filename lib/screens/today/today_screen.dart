import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/dloop_top_bar.dart';
import '../../widgets/earning_notification.dart';
import '../../widgets/in_app_notification_banner.dart';
import '../../widgets/header_sheets.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../theme/tokens.dart';
import 'widgets/kpi_strip.dart';
import 'widgets/active_mode_card.dart';
import 'widgets/activity_tab.dart';
import 'widgets/hot_zones.dart';
import 'widgets/wellness_card.dart';
import 'widgets/quick_actions_grid.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _isOnline = true;
  int _lastNetworkEarningsCount = 0;
  final _bannerController = InAppNotificationController();
  int _lastNotificationsCount = 0;

  static const _kChatbotIntroPref = 'has_seen_chatbot_intro_v2';

  @override
  void initState() {
    super.initState();
    _maybeShowChatbotIntro();
  }

  Future<void> _maybeShowChatbotIntro() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kChatbotIntroPref) == true) return;

    // Delay 1.2s so the screen is fully rendered
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    await prefs.setBool(_kChatbotIntroPref, true);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChatbotIntroSheet(),
    );
  }

  void _showSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _SearchSheet(),
    );
  }

  void _showNotifications() {
    context.push('/today/notifications');
  }

  void _toggleOnline() {
    setState(() {
      _isOnline = !_isOnline;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isOnline ? 'Sei online!' : 'Sei offline'),
        backgroundColor: _isOnline ? Colors.green : Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationController = ref.watch(earningNotificationControllerProvider);
    final networkState = ref.watch(networkEarningsProvider);
    final notifState = ref.watch(notificationsProvider);
    final unreadCount = notifState.unreadCount;

    // Show banner for new notifications
    if (notifState.notifications.length > _lastNotificationsCount && _lastNotificationsCount > 0) {
      final latest = notifState.notifications.first;
      if (!latest.isRead) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _bannerController.show(
            title: latest.title,
            body: latest.body,
            type: latest.type,
            onTap: () => context.push('/today/notifications'),
          );
        });
      }
    }
    _lastNotificationsCount = notifState.notifications.length;

    // Rileva nuovi guadagni dal Network e mostra popup celebration
    if (networkState.networkEarnings.length > _lastNetworkEarningsCount && _lastNetworkEarningsCount > 0) {
      // Nuovo guadagno dal Network! Mostra popup
      // Stream ordina per processed_at DESC, quindi il più recente è il primo
      final latestEarning = networkState.networkEarnings.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notificationController.show(
          amount: latestEarning.amount,
          source: latestEarning.description,
          hasTip: false,
          isRushBonus: latestEarning.description.contains('Bonus'),
        );
      });
    }
    _lastNetworkEarningsCount = networkState.networkEarnings.length;

    return InAppNotificationOverlay(
      controller: _bannerController,
      child: EarningNotificationOverlay(
        controller: notificationController,
        child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Bar stile Revolut
                DloopTopBar(
                  isOnline: _isOnline,
                  notificationCount: unreadCount,
                  onSearchTap: () => SearchSheet.show(context, hint: 'Cerca zone, ordini...'),
                  onNotificationTap: () => NotificationsSheet.show(context),
                  onQuickActionTap: () => QuickActionsSheet.show(context),
                  searchHint: 'Cerca zone, ordini...',
                ),
                // Contenuto scrollabile
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const KpiStrip(),
                            const SizedBox(height: 24),
                            const ActiveModeCard(),
                            const SizedBox(height: 12),
                            const ActivityTab(),
                            const SizedBox(height: 24),
                            const HotZones(),
                            const SizedBox(height: 24),
                            const QuickActionsGrid(),
                            const SizedBox(height: 24),
                            const WellnessCard(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // FAB Assistente AI — posizionato in basso a destra
            Positioned(
              right: 16,
              bottom: 12,
              child: GestureDetector(
                onTap: () => context.push('/today/ai-chat'),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF00E676)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C853).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.assistant,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _SearchSheet extends StatelessWidget {
  const _SearchSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Search input
              TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cerca zone, ordini, guadagni...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Quick filters
              Text(
                'Ricerche rapide',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickFilter(label: 'Zone calde', icon: Icons.local_fire_department),
                  _QuickFilter(label: 'Ordini oggi', icon: Icons.receipt_long),
                  _QuickFilter(label: 'Guadagni settimana', icon: Icons.trending_up),
                  _QuickFilter(label: 'Bonus attivi', icon: Icons.card_giftcard),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Recenti',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _RecentSearchItem(text: 'Zona Centro Milano'),
              _RecentSearchItem(text: 'Ordine #12847'),
              _RecentSearchItem(text: 'Bonus weekend'),
            ],
          ),
        );
      },
    );
  }
}

class _QuickFilter extends StatelessWidget {
  final String label;
  final IconData icon;

  const _QuickFilter({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFF6B00)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RecentSearchItem extends StatelessWidget {
  final String text;

  const _RecentSearchItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.history, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Icon(Icons.north_west, size: 16, color: Colors.grey.shade600),
        ],
      ),
    );
  }
}

// ── Chatbot Intro Bottom Sheet ──────────────────────────────────

class _ChatbotIntroSheet extends StatelessWidget {
  const _ChatbotIntroSheet();

  static const _examples = [
    'Quanto ho guadagnato oggi?',
    'Dove ci sono piu ordini?',
    'Come funziona la cauzione?',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Animated-style icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.earningsGreen.withOpacity(0.2),
                    AppColors.turboOrange.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(
                Icons.assistant,
                size: 38,
                color: AppColors.earningsGreen,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Hai un assistente personale',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Subtitle — simple language, no tech jargon
            Text(
              'Chiedimi quanto hai guadagnato, dove sono le zone '
              'calde, o come funziona la consegna luxury.\n'
              'Sono qui per aiutarti, 24/7.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Example chips
            Text(
              'Prova a chiedere:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _examples.map((text) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/today/ai-chat');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.turboOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.turboOrange.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      text,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.turboOrange,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // CTA primary
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/today/ai-chat');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.turboOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Prova ora',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // CTA secondary
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Magari dopo',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
