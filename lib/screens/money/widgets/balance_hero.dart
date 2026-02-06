import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class BalanceHero extends StatefulWidget {
  const BalanceHero({super.key});

  @override
  State<BalanceHero> createState() => _BalanceHeroState();
}

class _BalanceHeroState extends State<BalanceHero> {
  bool _isPendingExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SALDO DISPONIBILE',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF9E9E9E),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '\u20AC 1.847,50',
          style: GoogleFonts.inter(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        _buildPendingCard(cs),
      ],
    );
  }

  Widget _buildPendingCard(ColorScheme cs) {
    return GestureDetector(
      onTap: () => setState(() => _isPendingExpanded = !_isPendingExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.earningsGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.earningsGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppColors.earningsGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '+\u20AC 234,20 in arrivo',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.earningsGreen,
                    ),
                  ),
                ),
                Icon(
                  _isPendingExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.earningsGreen,
                ),
              ],
            ),
            if (_isPendingExpanded) ...[
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: AppColors.earningsGreen.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              _buildPendingRow('Consegne', '€180,00', '3 in elaborazione', 'oggi', AppColors.turboOrange),
              const SizedBox(height: 8),
              _buildPendingRow('Network', '€34,20', '2 commissioni', 'domani', AppColors.earningsGreen),
              const SizedBox(height: 8),
              _buildPendingRow('Market', '€20,00', '1 ordine', 'lun 10', AppColors.bonusPurple),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRow(String label, String amount, String detail, String time, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                detail,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
