import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class KpiStrip extends StatelessWidget {
  const KpiStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(child: _KpiCard(
          label: 'GUADAGNO OGGI',
          value: '€ 142.60',
          trailing: Icon(Icons.trending_up, size: 16, color: AppColors.earningsGreen),
        )),
        const SizedBox(width: 12),
        Expanded(child: _KpiCard(
          label: 'ORDINI',
          value: '8',
          trailing: Icon(Icons.circle, size: 8, color: cs.onSurfaceVariant),
        )),
        const SizedBox(width: 12),
        Expanded(child: _KpiCard(
          label: 'STREAK',
          value: '12 giorni',
          trailing: Icon(Icons.local_fire_department, size: 16, color: AppColors.turboOrange),
        )),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const _KpiCard({
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
