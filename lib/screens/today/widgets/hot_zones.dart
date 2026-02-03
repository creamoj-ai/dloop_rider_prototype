import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';
import '../../../models/zone_data.dart';
import '../../../services/zones_service.dart';

class HotZones extends StatefulWidget {
  const HotZones({super.key});

  @override
  State<HotZones> createState() => _HotZonesState();
}

class _HotZonesState extends State<HotZones> {
  List<ZoneData> _zones = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      final zones = await ZonesService.getHotZones();
      if (mounted) {
        setState(() {
          _zones = zones;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

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
            const Spacer(),
            // Refresh button
            IconButton(
              onPressed: _isLoading ? null : () {
                setState(() => _isLoading = true);
                _loadZones();
              },
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                    )
                  : const Icon(Icons.refresh, color: Colors.white54, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Scrollable zone cards
        SizedBox(
          height: 120,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.turboOrange))
              : _error != null
                  ? Center(
                      child: Text(
                        'Errore caricamento zone',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                      ),
                    )
                  : ListView.separated(
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
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/today/route'),
            icon: const Icon(Icons.route, size: 18),
            label: Text(
              'VEDI ROUTE OTTIMIZZATA',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.earningsGreen,
              side: BorderSide(color: AppColors.earningsGreen.withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

Color _demandColor(ZoneDemand d) => switch (d) {
  ZoneDemand.alta => AppColors.earningsGreen,
  ZoneDemand.media => AppColors.statsGold,
  ZoneDemand.bassa => Colors.grey,
};

String _demandLabel(ZoneDemand d) => switch (d) {
  ZoneDemand.alta => 'ALTA',
  ZoneDemand.media => 'MEDIA',
  ZoneDemand.bassa => 'BASSA',
};

class _ZoneCard extends StatelessWidget {
  final ZoneData zone;
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
            // Name
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
              '${zone.ordersHourLabel}  •  ${zone.distanceLabel}',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
            // Earning
            Text(
              zone.earningLabel,
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
