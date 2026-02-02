import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class BalanceHero extends StatefulWidget {
  const BalanceHero({super.key});

  @override
  State<BalanceHero> createState() => _BalanceHeroState();
}

class _BalanceHeroState extends State<BalanceHero> {
  final Set<int> _selected = {0, 1, 2};

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 4),
        Text(
          '+\u20AC 234,20 in arrivo',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.earningsGreen,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _chip(0, 'Consegne', AppColors.turboOrange),
            const SizedBox(width: 8),
            _chip(1, 'Network', AppColors.earningsGreen),
            const SizedBox(width: 8),
            _chip(2, 'Market', AppColors.bonusPurple),
          ],
        ),
      ],
    );
  }

  Widget _chip(int index, String label, Color color) {
    final isSelected = _selected.contains(index);
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : color,
        ),
      ),
      selected: isSelected,
      onSelected: (v) => setState(() {
        if (v) {
          _selected.add(index);
        } else {
          _selected.remove(index);
        }
      }),
      backgroundColor: Colors.transparent,
      selectedColor: color.withOpacity(0.25),
      side: BorderSide(color: color.withOpacity(isSelected ? 0 : 0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
