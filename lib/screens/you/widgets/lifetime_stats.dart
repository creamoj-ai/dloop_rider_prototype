import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/dloop_card.dart';

class LifetimeStats extends StatelessWidget {
  const LifetimeStats({super.key});

  @override
  Widget build(BuildContext context) {
    return DloopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STATISTICHE LIFETIME', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF9E9E9E), letterSpacing: 1)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _gridStat('1.247', 'Ordini totali'),
              _gridStat('\u20AC 18.450', 'Guadagno totale'),
              _gridStat('3.820', 'Km percorsi'),
              _gridStat('4.8 \u2605', 'Rating medio'),
              _gridStat('\u20AC 87.40', 'Best day'),
              _gridStat('892', 'Ore totali'),
            ],
          ),
          const Divider(color: Color(0xFF252529), height: 32),
          _menuItem(context, Icons.settings, 'Impostazioni', null),
          _menuItem(context, Icons.support_agent, 'Supporto', null),
          _menuItem(context, Icons.logout, 'Logout', Colors.red),
        ],
      ),
    );
  }

  Widget _gridStat(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9E9E9E)), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, Color? color) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? Colors.white, size: 20),
      title: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: color ?? Colors.white)),
      trailing: Icon(Icons.chevron_right, color: const Color(0xFF9E9E9E), size: 20),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(label == 'Logout' ? 'Logout effettuato' : label)),
      ),
    );
  }
}
