import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class HotZones extends StatelessWidget {
  const HotZones({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.local_fire_department, color: AppColors.turboOrange, size: 22),
            const SizedBox(width: 8),
            Text(
              'ZONE CALDE',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.urgentRed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'LIVE',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Scrollable zone cards
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _zones.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _ZoneCard(zone: _zones[i]),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/today/zone'),
            icon: const Icon(Icons.map, size: 18),
            label: Text(
              'VEDI MAPPA COMPLETA',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.routeBlue,
              side: BorderSide(color: AppColors.routeBlue.withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

enum _Demand { alta, media, bassa }

class _ZoneData {
  final String name;
  final _Demand demand;
  final String ordersHour;
  final String distance;
  final String earning;

  const _ZoneData({
    required this.name,
    required this.demand,
    required this.ordersHour,
    required this.distance,
    required this.earning,
  });
}

const _zones = [
  _ZoneData(name: 'Milano Centro', demand: _Demand.alta, ordersHour: '~12 ordini/h', distance: '0.5 km', earning: '€16-20/h'),
  _ZoneData(name: 'Navigli', demand: _Demand.alta, ordersHour: '~10 ordini/h', distance: '1.2 km', earning: '€14-18/h'),
  _ZoneData(name: 'Porta Romana', demand: _Demand.media, ordersHour: '~8 ordini/h', distance: '2.0 km', earning: '€12-15/h'),
  _ZoneData(name: 'Isola', demand: _Demand.media, ordersHour: '~6 ordini/h', distance: '3.1 km', earning: '€10-13/h'),
  _ZoneData(name: 'Città Studi', demand: _Demand.bassa, ordersHour: '~4 ordini/h', distance: '4.5 km', earning: '€8-10/h'),
];

Color _demandColor(_Demand d) => switch (d) {
  _Demand.alta => AppColors.earningsGreen,
  _Demand.media => AppColors.statsGold,
  _Demand.bassa => Colors.grey,
};

String _demandLabel(_Demand d) => switch (d) {
  _Demand.alta => 'ALTA',
  _Demand.media => 'MEDIA',
  _Demand.bassa => 'BASSA',
};

class _ZoneCard extends StatelessWidget {
  final _ZoneData zone;
  const _ZoneCard({required this.zone});

  @override
  Widget build(BuildContext context) {
    final color = _demandColor(zone.demand);
    return GestureDetector(
      onTap: () => context.push('/today/zone'),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1E),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Name + demand badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    zone.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Demand badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _demandLabel(zone.demand),
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Stats row
            Text(
              '${zone.ordersHour}  •  ${zone.distance}',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
            // Earning
            Text(
              zone.earning,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
