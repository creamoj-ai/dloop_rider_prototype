import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class BalanceHero extends StatelessWidget {
  const BalanceHero({super.key});

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
      ],
    );
  }
}
