import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';

enum KpiTrend { up, down, neutral }

class DloopKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final KpiTrend? trend;

  const DloopKpiTile({
    super.key,
    required this.label,
    required this.value,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF9E9E9E),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (trend != null && trend != KpiTrend.neutral) ...[
              const SizedBox(width: 6),
              Icon(
                trend == KpiTrend.up ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
                color: trend == KpiTrend.up
                    ? AppColors.earningsGreen
                    : AppColors.urgentRed,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
