import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/tokens.dart';

class ZoneMapScreen extends StatefulWidget {
  const ZoneMapScreen({super.key});

  @override
  State<ZoneMapScreen> createState() => _ZoneMapScreenState();
}

class _ZoneMapScreenState extends State<ZoneMapScreen> {
  int _selectedZone = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final zone = _mapZones[_selectedZone];

    return Scaffold(
      appBar: AppBar(
        title: Text('Mappa Zone', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, size: 20),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Centrando sulla tua posizione...')),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              // Fake map area
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    // Map background with grid
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF12141A),
                      child: CustomPaint(painter: _GridPainter()),
                    ),
                    // Heat zones (colored circles)
                    ..._mapZones.asMap().entries.map((e) => _buildHeatCircle(e.key, e.value)),
                    // Rider position
                    Positioned(
                      top: 95,
                      left: 170,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.routeBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [BoxShadow(color: AppColors.routeBlue.withOpacity(0.5), blurRadius: 12)],
                        ),
                        child: const Icon(Icons.delivery_dining, size: 16, color: Colors.white),
                      ),
                    ),
                    // Nearby orders pins
                    ..._nearbyOrders.map((o) => Positioned(
                      top: o.y,
                      left: o.x,
                      child: GestureDetector(
                        onTap: () => _showOrderDetail(context, o),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.turboOrange,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4)],
                          ),
                          child: Text(o.price, style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    )),
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
                            const SizedBox(height: 4),
                            _legendDot(AppColors.turboOrange, 'Ordini'),
                          ],
                        ),
                      ),
                    ),
                    // Live indicator
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
                  itemCount: _mapZones.length,
                  itemBuilder: (_, i) {
                    final z = _mapZones[i];
                    final selected = i == _selectedZone;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedZone = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? z.color.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? z.color : Colors.white24),
                          ),
                          child: Text(
                            z.name,
                            style: GoogleFonts.inter(
                              color: selected ? z.color : Colors.white54,
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
                          Container(width: 4, height: 24, decoration: BoxDecoration(color: zone.color, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(zone.name, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: zone.color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text(zone.demandLabel, style: GoogleFonts.inter(color: zone.color, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // KPI row
                      Row(
                        children: [
                          _kpiPill(Icons.shopping_bag, zone.ordersHour, 'ordini/h', cs),
                          const SizedBox(width: 10),
                          _kpiPill(Icons.euro, zone.earning, 'stima/h', cs),
                          const SizedBox(width: 10),
                          _kpiPill(Icons.near_me, zone.distance, 'da te', cs),
                          const SizedBox(width: 10),
                          _kpiPill(Icons.people, zone.riders, 'rider', cs),
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
                      const SizedBox(height: 12),
                      // Nearby orders in this zone
                      Text('Ordini disponibili', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...zone.orders.map((o) => _orderTile(o, cs)),
                      const SizedBox(height: 16),
                      // CTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openGoogleMaps(zone.name),
                          icon: const Icon(Icons.navigation, size: 18),
                          label: Text('VAI IN QUESTA ZONA', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: zone.color,
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
          ),
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps(String zoneName) async {
    final encodedAddress = Uri.encodeComponent('$zoneName, Milano, Italia');
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildHeatCircle(int index, _MapZone zone) {
    final selected = index == _selectedZone;
    return Positioned(
      top: zone.mapY - zone.radius,
      left: zone.mapX - zone.radius,
      child: GestureDetector(
        onTap: () => setState(() => _selectedZone = index),
        child: Container(
          width: zone.radius * 2,
          height: zone.radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: zone.color.withOpacity(selected ? 0.3 : 0.15),
            border: selected ? Border.all(color: zone.color, width: 2) : null,
          ),
          child: Center(
            child: Text(
              zone.shortName,
              style: GoogleFonts.inter(color: zone.color, fontSize: 10, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
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

  Widget _orderTile(_ZoneOrder order, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.turboOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fastfood, size: 18, color: AppColors.turboOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.restaurant, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${order.distance} • ${order.time}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text(order.price, style: GoogleFonts.inter(color: AppColors.earningsGreen, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _showOrderDetail(BuildContext context, _NearbyOrder order) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fastfood, color: AppColors.turboOrange),
                const SizedBox(width: 10),
                Text(order.restaurant, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.euro, 'Compenso: ${order.price}'),
            _detailRow(Icons.near_me, 'Distanza: ${order.dist}'),
            _detailRow(Icons.location_on, 'Consegna: ${order.destination}'),
            _detailRow(Icons.timer, 'Tempo stimato: ${order.eta}'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ordine da ${order.restaurant} accettato!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.earningsGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('ACCETTA ORDINE', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 10),
          Text(text, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

// Grid painter for fake map background
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Street-like lines
    final streetPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), streetPaint);
    canvas.drawLine(Offset(size.width * 0.45, 0), Offset(size.width * 0.45, size.height), streetPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.65), streetPaint);
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.3, size.height), streetPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.8, size.height), streetPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Data models
class _ZoneOrder {
  final String restaurant;
  final String distance;
  final String time;
  final String price;
  const _ZoneOrder(this.restaurant, this.distance, this.time, this.price);
}

class _NearbyOrder {
  final double x;
  final double y;
  final String price;
  final String restaurant;
  final String dist;
  final String destination;
  final String eta;
  const _NearbyOrder({required this.x, required this.y, required this.price, required this.restaurant, required this.dist, required this.destination, required this.eta});
}

class _MapZone {
  final String name;
  final String shortName;
  final String demandLabel;
  final Color color;
  final double mapX;
  final double mapY;
  final double radius;
  final String ordersHour;
  final String earning;
  final String distance;
  final String riders;
  final String trending;
  final String trendText;
  final List<_ZoneOrder> orders;

  const _MapZone({
    required this.name,
    required this.shortName,
    required this.demandLabel,
    required this.color,
    required this.mapX,
    required this.mapY,
    required this.radius,
    required this.ordersHour,
    required this.earning,
    required this.distance,
    required this.riders,
    required this.trending,
    required this.trendText,
    required this.orders,
  });
}

const _mapZones = [
  _MapZone(
    name: 'Milano Centro',
    shortName: 'Centro',
    demandLabel: 'ALTA',
    color: AppColors.earningsGreen,
    mapX: 185, mapY: 80, radius: 50,
    ordersHour: '12', earning: '€18', distance: '0.5km', riders: '8',
    trending: 'up',
    trendText: 'Domanda in crescita +25% rispetto a ieri',
    orders: [
      _ZoneOrder('Pizzeria Da Mario', '0.3 km', '~8 min', '€4.50'),
      _ZoneOrder('Sushi Zen', '0.5 km', '~12 min', '€5.80'),
      _ZoneOrder("McDonald's Duomo", '0.2 km', '~6 min', '€3.90'),
    ],
  ),
  _MapZone(
    name: 'Navigli',
    shortName: 'Navigli',
    demandLabel: 'ALTA',
    color: AppColors.earningsGreen,
    mapX: 120, mapY: 170, radius: 45,
    ordersHour: '10', earning: '€16', distance: '1.2km', riders: '6',
    trending: 'up',
    trendText: 'Zona aperitivo — picco dalle 18:00 alle 22:00',
    orders: [
      _ZoneOrder('Trattoria Milanese', '1.0 km', '~15 min', '€5.20'),
      _ZoneOrder('Burger King Navigli', '1.3 km', '~10 min', '€4.10'),
    ],
  ),
  _MapZone(
    name: 'Porta Romana',
    shortName: 'P.Romana',
    demandLabel: 'MEDIA',
    color: AppColors.statsGold,
    mapX: 280, mapY: 160, radius: 40,
    ordersHour: '8', earning: '€13', distance: '2.0km', riders: '4',
    trending: 'flat',
    trendText: 'Domanda stabile — buona per consegne regolari',
    orders: [
      _ZoneOrder('Poke House', '1.8 km', '~18 min', '€4.80'),
      _ZoneOrder('Rossopomodoro', '2.1 km', '~20 min', '€5.50'),
    ],
  ),
  _MapZone(
    name: 'Isola',
    shortName: 'Isola',
    demandLabel: 'MEDIA',
    color: AppColors.statsGold,
    mapX: 250, mapY: 40, radius: 35,
    ordersHour: '6', earning: '€11', distance: '3.1km', riders: '3',
    trending: 'down',
    trendText: 'Domanda in calo — pochi ristoranti aperti ora',
    orders: [
      _ZoneOrder('Kebab House', '3.0 km', '~22 min', '€4.00'),
    ],
  ),
  _MapZone(
    name: 'Città Studi',
    shortName: 'C.Studi',
    demandLabel: 'BASSA',
    color: Colors.grey,
    mapX: 340, mapY: 90, radius: 30,
    ordersHour: '4', earning: '€9', distance: '4.5km', riders: '2',
    trending: 'down',
    trendText: 'Zona universitaria — picco solo a pranzo',
    orders: [
      _ZoneOrder('Panino Giusto', '4.3 km', '~25 min', '€3.50'),
    ],
  ),
];

const _nearbyOrders = [
  _NearbyOrder(x: 150, y: 60, price: '€4.50', restaurant: 'Pizzeria Da Mario', dist: '0.3 km', destination: 'Via Torino 45', eta: '8 min'),
  _NearbyOrder(x: 210, y: 95, price: '€5.80', restaurant: 'Sushi Zen', dist: '0.5 km', destination: 'Corso Buenos Aires 12', eta: '12 min'),
  _NearbyOrder(x: 100, y: 145, price: '€5.20', restaurant: 'Trattoria Milanese', dist: '1.0 km', destination: 'Ripa di Porta Ticinese 7', eta: '15 min'),
  _NearbyOrder(x: 280, y: 130, price: '€4.80', restaurant: 'Poke House', dist: '1.8 km', destination: 'Via Ripamonti 20', eta: '18 min'),
  _NearbyOrder(x: 310, y: 55, price: '€3.50', restaurant: 'Panino Giusto', dist: '4.3 km', destination: 'Piazza Leonardo 1', eta: '25 min'),
];
