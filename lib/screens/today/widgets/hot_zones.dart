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
            onPressed: () => _showExploreOptions(context),
            icon: const Icon(Icons.explore, size: 18),
            label: Text(
              'ESPLORA ZONE',
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

  void _showExploreOptions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.explore, color: AppColors.routeBlue, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Esplora Zone',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ExploreOption(
              icon: Icons.map,
              title: 'Mappa Completa',
              subtitle: 'Visualizza tutte le zone sulla mappa',
              color: AppColors.routeBlue,
              onTap: () {
                Navigator.pop(context);
                context.push('/today/zone');
              },
            ),
            const SizedBox(height: 12),
            _ExploreOption(
              icon: Icons.route,
              title: 'Guadagna di Più',
              subtitle: 'Percorso smart per più ordini e meno km',
              color: AppColors.earningsGreen,
              onTap: () {
                Navigator.pop(context);
                context.push('/today/route');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

class _ExploreOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExploreOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}
