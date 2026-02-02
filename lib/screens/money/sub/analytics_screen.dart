import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Analytics', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(cs, 'Earn vs Grow ROI', AppColors.turboOrange, [
              _stat('Earn', '\u20AC 2.400/mese', AppColors.turboOrange),
              _stat('Grow', '\u20AC 340/mese', AppColors.earningsGreen),
            ]),
            const SizedBox(height: 12),
            _card(cs, 'Trend Settimanale', AppColors.earningsGreen, [
              _stat('+12%', 'vs settimana scorsa', AppColors.earningsGreen),
            ]),
            const SizedBox(height: 12),
            _card(cs, 'Best Day', AppColors.bonusPurple, [
              _stat('Martedi', '\u20AC 87.40', AppColors.bonusPurple),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _card(ColorScheme cs, String title, Color accent, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: accent, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(value, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9E9E9E))),
        ],
      ),
    );
  }
}
