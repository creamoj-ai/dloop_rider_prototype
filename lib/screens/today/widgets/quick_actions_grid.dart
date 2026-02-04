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
  // Notification state
  int _whatsappNotifications = 3;
  int _supportNotifications = 1;
  int _communityNotifications = 12;

  // Network stats (mock)
  final int _networkActiveRiders = 12;
  final double _networkMonthlyEarnings = 47.50;

  int get _totalNotifications =>
      _whatsappNotifications + _supportNotifications + _communityNotifications;

  void _markWhatsappRead() => setState(() => _whatsappNotifications = 0);
  void _markSupportRead() => setState(() => _supportNotifications = 0);
  void _markCommunityRead() => setState(() => _communityNotifications = 0);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Prima riga: Assistente + Strumenti
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.smart_toy,
                  label: 'Assistente',
                  subtitle: '$_totalNotifications messaggi',
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
                  subtitle: 'Utility rider',
                  color: AppColors.statsGold,
                  onTap: () => _showToolkit(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Seconda riga: Network + Obiettivi
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.people,
                  label: 'Network',
                  subtitle: '$_networkActiveRiders attivi',
                  subtitleExtra: '+€${_networkMonthlyEarnings.toStringAsFixed(0)}/mese',
                  color: AppColors.routeBlue,
                  onTap: () => _showNetworkSheet(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  icon: Icons.emoji_events,
                  label: 'Obiettivi',
                  subtitle: '12 giorni streak',
                  subtitleExtra: 'Top 5% zona',
                  color: AppColors.bonusPurple,
                  onTap: () => _showMotivation(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showNetworkSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _NetworkSheet(
          scrollController: scrollController,
          activeRiders: _networkActiveRiders,
          monthlyEarnings: _networkMonthlyEarnings,
        ),
      ),
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
            _botItem(Icons.shopping_bag, 'WhatsApp Market Bot', 'Gestisci ordini del tuo marketplace', AppColors.earningsGreen, cs, context, notificationCount: _whatsappNotifications, onRead: _markWhatsappRead),
            _botItem(Icons.support_agent, 'Supporto Rider', 'Parla con il supporto dloop', AppColors.routeBlue, cs, context, notificationCount: _supportNotifications, onRead: _markSupportRead),
            _botItem(Icons.group, 'Community Riders', 'Chat gruppo riders della tua zona', AppColors.bonusPurple, cs, context, notificationCount: _communityNotifications, onRead: _markCommunityRead),
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
          SnackBar(content: Text('Apertura $title...'), backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
                if (notificationCount > 0)
                  Positioned(
                    top: -4, right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10), border: Border.all(color: cs.surface, width: 1.5)),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(notificationCount > 99 ? '99+' : '$notificationCount', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
              ]),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
      child: Row(children: [
        Icon(icon, size: 20, color: cs.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(text, style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface)),
      ]),
    );
  }
}

/// Tile per la grid 2x2
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? subtitleExtra;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.subtitleExtra,
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
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 24, color: color),
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          top: -4, right: -4,
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
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
              if (subtitleExtra != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitleExtra!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.earningsGreen,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom Sheet Network completo
class _NetworkSheet extends StatefulWidget {
  final ScrollController scrollController;
  final int activeRiders;
  final double monthlyEarnings;

  const _NetworkSheet({
    required this.scrollController,
    required this.activeRiders,
    required this.monthlyEarnings,
  });

  @override
  State<_NetworkSheet> createState() => _NetworkSheetState();
}

class _NetworkSheetState extends State<_NetworkSheet> {
  String _filter = 'tutti';

  // Mock data
  final List<Map<String, dynamic>> _members = [
    {'name': 'Luca Rossi', 'status': 'active', 'orders': 142, 'earned': 8.50, 'days': 45, 'rank': 1},
    {'name': 'Anna Martini', 'status': 'active', 'orders': 98, 'earned': 5.90, 'days': 32, 'rank': 2},
    {'name': 'Marco Polo', 'status': 'active', 'orders': 76, 'earned': 4.55, 'days': 28, 'rank': 3},
    {'name': 'Sara Verdi', 'status': 'active', 'orders': 54, 'earned': 3.20, 'days': 21, 'rank': 4},
    {'name': 'Paolo Bianchi', 'status': 'pending', 'orders': 2, 'earned': 0.0, 'days': 5, 'rank': 0},
    {'name': 'Giulia Neri', 'status': 'pending', 'orders': 0, 'earned': 0.0, 'days': 2, 'rank': 0},
  ];

  List<Map<String, dynamic>> get _filteredMembers {
    if (_filter == 'attivi') return _members.where((m) => m['status'] == 'active').toList();
    if (_filter == 'in_attesa') return _members.where((m) => m['status'] == 'pending').toList();
    return _members;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeCount = _members.where((m) => m['status'] == 'active').length;
    final pendingCount = _members.where((m) => m['status'] == 'pending').length;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.routeBlue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.people, color: AppColors.routeBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Il tuo network', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text('Guadagni passivi dai tuoi invitati', style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.routeBlue.withValues(alpha: 0.2), AppColors.routeBlue.withValues(alpha: 0.05)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.routeBlue.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  '€ ${widget.monthlyEarnings.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.earningsGreen),
                ),
                const SizedBox(height: 4),
                Text('Guadagni passivi questo mese', style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statPill(cs, '${_members.length}', 'Totali', AppColors.routeBlue),
                    _statPill(cs, '$activeCount', 'Attivi', AppColors.earningsGreen),
                    _statPill(cs, '$pendingCount', 'In attesa', AppColors.turboOrange),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Come funziona
          _buildHowItWorks(cs),
          const SizedBox(height: 24),

          // Filtri
          Row(
            children: [
              Text('Membri', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
              const Spacer(),
              _filterChip(cs, 'Tutti', 'tutti'),
              const SizedBox(width: 8),
              _filterChip(cs, 'Attivi', 'attivi'),
              const SizedBox(width: 8),
              _filterChip(cs, 'In attesa', 'in_attesa'),
            ],
          ),
          const SizedBox(height: 16),

          // Lista membri
          ..._filteredMembers.map((m) => _memberTile(cs, m)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statPill(ColorScheme cs, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.statsGold),
              const SizedBox(width: 8),
              Text('Come guadagni', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          _howStep('1', '€10 bonus per ogni rider attivato'),
          _howStep('2', '6% sui guadagni (primi 3 mesi)'),
          _howStep('3', '3% sui guadagni (dal 4° mese)'),
        ],
      ),
    );
  }

  Widget _howStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(color: AppColors.routeBlue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(num, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.routeBlue))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70))),
        ],
      ),
    );
  }

  Widget _filterChip(ColorScheme cs, String label, String value) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.routeBlue.withValues(alpha: 0.2) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AppColors.routeBlue.withValues(alpha: 0.5)) : null,
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? AppColors.routeBlue : cs.onSurfaceVariant)),
      ),
    );
  }

  Widget _memberTile(ColorScheme cs, Map<String, dynamic> member) {
    final isActive = member['status'] == 'active';
    final rank = member['rank'] as int;

    String rankEmoji = '';
    if (rank == 1) rankEmoji = '🥇 ';
    if (rank == 2) rankEmoji = '🥈 ';
    if (rank == 3) rankEmoji = '🥉 ';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isActive ? AppColors.earningsGreen.withValues(alpha: 0.15) : cs.onSurfaceVariant.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.person, size: 24, color: isActive ? AppColors.earningsGreen : cs.onSurfaceVariant),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$rankEmoji${member['name']}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(isActive ? Icons.check_circle : Icons.hourglass_empty, size: 12, color: isActive ? AppColors.earningsGreen : AppColors.turboOrange),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? 'Attivo da ${member['days']} giorni' : 'In attesa (${member['orders']}/5 ordini)',
                      style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(height: 2),
                  Text('${member['orders']} ordini completati', style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          if (isActive)
            Text('+€${(member['earned'] as double).toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.earningsGreen))
          else
            Text('-', style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
