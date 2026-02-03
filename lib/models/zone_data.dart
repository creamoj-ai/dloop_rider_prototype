enum ZoneDemand { alta, media, bassa }

class ZoneData {
  final String id;
  final String name;
  final ZoneDemand demand;
  final int ordersPerHour;
  final double distanceKm;
  final double earningMin;
  final double earningMax;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  const ZoneData({
    required this.id,
    required this.name,
    required this.demand,
    required this.ordersPerHour,
    required this.distanceKm,
    required this.earningMin,
    required this.earningMax,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  factory ZoneData.fromJson(Map<String, dynamic> json) {
    return ZoneData(
      id: json['id'] as String,
      name: json['name'] as String,
      demand: _parseDemand(json['demand'] as String),
      ordersPerHour: json['orders_per_hour'] as int,
      distanceKm: (json['distance_km'] as num).toDouble(),
      earningMin: (json['earning_min'] as num).toDouble(),
      earningMax: (json['earning_max'] as num).toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static ZoneDemand _parseDemand(String value) {
    switch (value.toLowerCase()) {
      case 'alta':
        return ZoneDemand.alta;
      case 'media':
        return ZoneDemand.media;
      case 'bassa':
      default:
        return ZoneDemand.bassa;
    }
  }

  String get ordersHourLabel => '~$ordersPerHour ordini/h';
  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';
  String get earningLabel => '€${earningMin.toInt()}-${earningMax.toInt()}/h stima';
}
