import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.route,
            label: 'Route',
            color: AppColors.earningsGreen,
            onTap: () => context.push('/today/route'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            icon: Icons.build,
            label: 'Toolkit',
            color: AppColors.statsGold,
            onTap: () => _showToolkit(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            icon: Icons.emoji_events,
            label: 'Motivation',
            color: AppColors.bonusPurple,
            onTap: () => _showMotivation(context),
          ),
        ),
      ],
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
            Text('Toolkit', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
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
            Text('Motivation', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
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

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
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
              Icon(icon, size: 28, color: color),
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
