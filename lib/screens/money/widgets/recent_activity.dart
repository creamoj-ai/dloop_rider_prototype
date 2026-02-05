import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/tokens.dart';

class RecentActivity extends StatelessWidget {
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Tx('Consegna Via Roma', '12 min fa', '+\u20AC 4.80', Icons.bolt, AppColors.turboOrange),
      _Tx('Commissione Dealer Marco', '1h fa', '+\u20AC 2.40', Icons.eco, AppColors.earningsGreen),
      _Tx('Vendita Box Premium', '2h fa', '+\u20AC 15.00', Icons.shopping_cart, AppColors.bonusPurple),
      _Tx('Consegna Piazza Duomo', '3h fa', '+\u20AC 5.20', Icons.bolt, AppColors.turboOrange),
      _Tx('Commissione Cliente Anna', '4h fa', '+\u20AC 1.80', Icons.eco, AppColors.earningsGreen),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attivita Recente',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/money/transactions'),
              child: Text(
                'Vedi tutto >',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.turboOrange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((tx) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tx.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(tx.icon, color: tx.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.desc,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        tx.time,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  tx.amount,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.earningsGreen,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

class _Tx {
  final String desc, time, amount;
  final IconData icon;
  final Color color;
  _Tx(this.desc, this.time, this.amount, this.icon, this.color);
}
