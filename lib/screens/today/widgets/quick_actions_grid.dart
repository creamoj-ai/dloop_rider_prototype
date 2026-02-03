import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class QuickActionsGrid extends StatefulWidget {
  const QuickActionsGrid({super.key});

  @override
  State<QuickActionsGrid> createState() => _QuickActionsGridState();
}

class _QuickActionsGridState extends State<QuickActionsGrid> {
  // Notification state for each chat type
  int _whatsappNotifications = 3;
  int _supportNotifications = 1;
  int _communityNotifications = 12;

  int get _totalNotifications =>
      _whatsappNotifications + _supportNotifications + _communityNotifications;

  void _markWhatsappRead() => setState(() => _whatsappNotifications = 0);
  void _markSupportRead() => setState(() => _supportNotifications = 0);
  void _markCommunityRead() => setState(() => _communityNotifications = 0);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.smart_toy,
            label: 'Assistente',
            color: AppColors.earningsGreen,
            onTap: () => _showBotOptions(context),
            badgeCount: _totalNotifications,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            icon: Icons.build,
            label: 'Strumenti',
            color: AppColors.statsGold,
            onTap: () => _showToolkit(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            icon: Icons.emoji_events,
            label: 'Obiettivi',
            color: AppColors.bonusPurple,
            onTap: () => _showMotivation(context),
          ),
        ),
      ],
    );
  }

  void _showBotOptions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
            Row(
              children: [
                const Icon(Icons.smart_toy, color: AppColors.earningsGreen, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Assistente & Chat',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _botItem(
              Icons.shopping_bag,
              'WhatsApp Market Bot',
              'Gestisci ordini del tuo marketplace',
              AppColors.earningsGreen,
              cs,
              context,
              notificationCount: _whatsappNotifications,
              onRead: _markWhatsappRead,
            ),
            _botItem(
              Icons.support_agent,
              'Supporto Rider',
              'Parla con il supporto dloop',
              AppColors.routeBlue,
              cs,
              context,
              notificationCount: _supportNotifications,
              onRead: _markSupportRead,
            ),
            _botItem(
              Icons.group,
              'Community Riders',
              'Chat gruppo riders della tua zona',
              AppColors.bonusPurple,
              cs,
              context,
              notificationCount: _communityNotifications,
              onRead: _markCommunityRead,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _botItem(IconData icon, String title, String subtitle, Color color, ColorScheme cs, BuildContext context, {int notificationCount = 0, VoidCallback? onRead}) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onRead?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apertura $title...'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (notificationCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cs.surface, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        notificationCount > 99 ? '99+' : '$notificationCount',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  void _showToolkit(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
            Text('Strumenti', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 16),
            _sheetItem(Icons.calculate, 'Calcolatore guadagni', cs),
            _sheetItem(Icons.timer, 'Timer turno', cs),
            _sheetItem(Icons.checklist, 'Checklist pre-turno', cs),
            _sheetItem(Icons.settings, 'Impostazioni veicolo', cs),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showMotivation(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
            Text('Obiettivi', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 16),
            _sheetItem(Icons.local_fire_department, 'Streak: 12 giorni consecutivi', cs),
            _sheetItem(Icons.star, 'Valutazione: 4.9 / 5.0', cs),
            _sheetItem(Icons.trending_up, 'Top 5% rider nella tua zona', cs),
            _sheetItem(Icons.emoji_events, 'Prossimo badge: 15 giorni streak', cs),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Widget _sheetItem(IconData icon, String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 28, color: color),
                  if (badgeCount > 0)
                    Positioned(
                      top: -6,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.urgentRed,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.surface, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
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
    );
  }
}
