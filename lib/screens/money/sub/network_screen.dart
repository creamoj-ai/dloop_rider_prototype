import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class NetworkScreen extends StatelessWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Network', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.earningsGreen,
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aggiungi contatto')),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI row
            Row(
              children: [
                _kpi(cs, '4', 'Dealer attivi'),
                const SizedBox(width: 12),
                _kpi(cs, '5', 'Clienti'),
                const SizedBox(width: 12),
                _kpi(cs, '\u20AC340', '/mese'),
              ],
            ),
            const SizedBox(height: 24),
            Text('Dealer', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),
            ...[
              _Dealer('Marco B.', 'Attivo', '\u20AC 120/mese'),
              _Dealer('Luca R.', 'Attivo', '\u20AC 95/mese'),
              _Dealer('Sara M.', 'Attivo', '\u20AC 80/mese'),
              _Dealer('Andrea P.', 'Potenziale', '\u20AC 45/mese'),
            ].map((d) => _dealerTile(cs, d)),
            const SizedBox(height: 24),
            Text('Clienti', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),
            ...[
              _Client('Anna V.', true, '24 ordini'),
              _Client('Paolo G.', true, '18 ordini'),
              _Client('Maria L.', false, '12 ordini'),
              _Client('Franco D.', false, '8 ordini'),
              _Client('Elena S.', false, '5 ordini'),
            ].map((c) => _clientTile(cs, c)),
          ],
        ),
      ),
    );
  }

  Widget _kpi(ColorScheme cs, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }

  Widget _dealerTile(ColorScheme cs, _Dealer d) {
    final isActive = d.status == 'Attivo';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: AppColors.earningsGreen.withOpacity(0.2),
            child: Icon(Icons.person, color: AppColors.earningsGreen, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 2),
              Text(d.earning, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E))),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isActive ? AppColors.earningsGreen : AppColors.turboOrange).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(d.status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                color: isActive ? AppColors.earningsGreen : AppColors.turboOrange)),
          ),
        ],
      ),
    );
  }

  Widget _clientTile(ColorScheme cs, _Client c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: AppColors.bonusPurple.withOpacity(0.2),
            child: Icon(Icons.person, color: AppColors.bonusPurple, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(c.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                if (c.isVip) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.statsGold.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text('VIP', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.statsGold)),
                  ),
                ],
              ],
            ),
          ),
          Text(c.orders, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E))),
        ],
      ),
    );
  }
}

class _Dealer {
  final String name, status, earning;
  _Dealer(this.name, this.status, this.earning);
}

class _Client {
  final String name;
  final bool isVip;
  final String orders;
  _Client(this.name, this.isVip, this.orders);
}
