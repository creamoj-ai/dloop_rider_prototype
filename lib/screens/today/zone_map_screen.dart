import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/zone_data.dart';
import '../../providers/location_provider.dart';
import '../../providers/zones_provider.dart';
import '../../services/location_service.dart';
import '../../theme/tokens.dart';

class ZoneMapScreen extends ConsumerStatefulWidget {
  const ZoneMapScreen({super.key});

  @override
  ConsumerState<ZoneMapScreen> createState() => _ZoneMapScreenState();
}

class _ZoneMapScreenState extends ConsumerState<ZoneMapScreen> {
  final _mapController = MapController();
  int _selectedZone = 0;
  bool _permissionRequested = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    if (_permissionRequested) return;
    _permissionRequested = true;
    final granted = await LocationService.ensurePermission();
    if (granted && mounted) {
      // Force re-read of position stream after permission granted
      ref.invalidate(positionStreamProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final zonesAsync = ref.watch(zonesStreamProvider);
    final posAsync = ref.watch(positionStreamProvider);
    final riderPos = posAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mappa Zone', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, size: 20),
            onPressed: () {
              if (riderPos != null) {
                _mapController.move(LatLng(riderPos.latitude, riderPos.longitude), 15.0);
              } else {
                final zones = zonesAsync.valueOrNull;
                if (zones != null && zones.isNotEmpty) {
                  _mapController.move(LatLng(zones.first.latitude, zones.first.longitude), 13.0);
                }
              }
            },
          ),
        ],
      ),
      body: zonesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.turboOrange)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
              const SizedBox(height: 12),
              Text('Errore caricamento zone', style: GoogleFonts.inter(color: Colors.white54)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(zonesStreamProvider),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
        data: (zones) {
          if (zones.isEmpty) {
            return Center(
              child: Text('Nessuna zona disponibile', style: GoogleFonts.inter(color: Colors.white54)),
            );
          }
          final safeIndex = _selectedZone.clamp(0, zones.length - 1);
          if (safeIndex != _selectedZone) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _selectedZone = safeIndex);
            });
          }
          final zone = zones[safeIndex];
          final mapCenter = riderPos != null
              ? LatLng(riderPos.latitude, riderPos.longitude)
              : LatLng(zones.first.latitude, zones.first.longitude);

          return Column(
            children: [
              // Map
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: mapCenter,
                        initialZoom: 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.dloop.rider.prototype',
                        ),
                        // Zone circles
                        CircleLayer(
                          circles: zones.asMap().entries.map((e) {
                            final z = e.value;
                            final selected = e.key == safeIndex;
                            return CircleMarker(
                              point: LatLng(z.latitude, z.longitude),
                              radius: z.radiusMeters,
                              useRadiusInMeter: true,
                              color: z.demandColor.withOpacity(selected ? 0.30 : 0.15),
                              borderColor: selected ? z.demandColor : z.demandColor.withOpacity(0.3),
                              borderStrokeWidth: selected ? 2.5 : 1,
                            );
                          }).toList(),
                        ),
                        // Zone labels
                        MarkerLayer(
                          markers: zones.asMap().entries.map((e) {
                            final z = e.value;
                            final selected = e.key == safeIndex;
                            return Marker(
                              point: LatLng(z.latitude, z.longitude),
                              width: 80,
                              height: 28,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedZone = e.key);
                                  _mapController.move(LatLng(z.latitude, z.longitude), 14.0);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: selected ? z.demandColor.withOpacity(0.9) : cs.surface.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: z.demandColor, width: selected ? 1.5 : 0.5),
                                  ),
                                  child: Text(
                                    z.shortName,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: selected ? Colors.white : z.demandColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        // Rider real position
                        if (riderPos != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(riderPos.latitude, riderPos.longitude),
                                width: 36,
                                height: 36,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.routeBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [BoxShadow(color: AppColors.routeBlue.withOpacity(0.5), blurRadius: 12)],
                                  ),
                                  child: const Icon(Icons.delivery_dining, size: 18, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    // Legend
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _legendDot(AppColors.earningsGreen, 'Alta domanda'),
                            const SizedBox(height: 4),
                            _legendDot(AppColors.statsGold, 'Media'),
                            const SizedBox(height: 4),
                            _legendDot(Colors.grey, 'Bassa'),
                          ],
                        ),
                      ),
                    ),
                    // Live badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.urgentRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('LIVE', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Zone selector strip
              Container(
                height: 50,
                color: cs.surface,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: zones.length,
                  itemBuilder: (_, i) {
                    final z = zones[i];
                    final selected = i == safeIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedZone = i);
                          _mapController.move(LatLng(z.latitude, z.longitude), 14.0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? z.demandColor.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? z.demandColor : Colors.white24),
                          ),
                          child: Text(
                            z.name,
                            style: GoogleFonts.inter(
                              color: selected ? z.demandColor : Colors.white54,
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Zone detail panel
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Zone header
                      Row(
                        children: [
                          Container(width: 4, height: 24, decoration: BoxDecoration(color: zone.demandColor, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(zone.name, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: zone.demandColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text(zone.demandLabel, style: GoogleFonts.inter(color: zone.demandColor, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // KPI row
                      Row(
                        children: [
                          _kpiPill(Icons.shopping_bag, '${zone.ordersPerHour}', 'ordini/h', cs),
                          const SizedBox(width: 10),
                          _kpiPill(Icons.euro, '€${zone.earningMax.toInt()}', 'stima/h', cs),
                          const SizedBox(width: 10),
                          _kpiPill(Icons.near_me, '${zone.distanceKm.toStringAsFixed(1)}km', 'da te', cs),
                          const SizedBox(width: 10),
                          _kpiPill(Icons.people, zone.ridersEstimate, 'rider', cs),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Trend
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(
                              zone.trending == 'up' ? Icons.trending_up : zone.trending == 'down' ? Icons.trending_down : Icons.trending_flat,
                              color: zone.trending == 'up' ? AppColors.earningsGreen : zone.trending == 'down' ? AppColors.urgentRed : AppColors.statsGold,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(zone.trendText, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // CTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openGoogleMaps(zone.name),
                          icon: const Icon(Icons.navigation, size: 18),
                          label: Text('VAI IN QUESTA ZONA', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: zone.demandColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openGoogleMaps(String zoneName) async {
    final encodedAddress = Uri.encodeComponent('$zoneName, Italia');
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 9)),
      ],
    );
  }

  Widget _kpiPill(IconData icon, String value, String label, ColorScheme cs) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Icon(icon, size: 16, color: Colors.white54),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
