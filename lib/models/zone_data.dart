import 'dart:ui';

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

  /// Short name for map labels (first word or abbreviation)
  String get shortName {
    if (name.length <= 8) return name;
    final parts = name.split(' ');
    if (parts.length == 1) return name.substring(0, 8);
    // "Milano Centro" → "Centro", "Porta Romana" → "P.Romana", "Città Studi" → "C.Studi"
    if (parts.first.length <= 3) return '${parts.first[0]}.${parts.skip(1).join(' ')}';
    return parts.last;
  }

  /// Radius in meters for map circle, derived from demand
  double get radiusMeters => switch (demand) {
    ZoneDemand.alta => 700,
    ZoneDemand.media => 550,
    ZoneDemand.bassa => 400,
  };

  /// Demand label for UI
  String get demandLabel => switch (demand) {
    ZoneDemand.alta => 'ALTA',
    ZoneDemand.media => 'MEDIA',
    ZoneDemand.bassa => 'BASSA',
  };

  /// Demand color for UI
  Color get demandColor => switch (demand) {
    ZoneDemand.alta => const Color(0xFF4CAF50),
    ZoneDemand.media => const Color(0xFFFFC107),
    ZoneDemand.bassa => const Color(0xFF9E9E9E),
  };

  /// Trending direction derived from demand + ordersPerHour
  String get trending => switch (demand) {
    ZoneDemand.alta => 'up',
    ZoneDemand.media => 'flat',
    ZoneDemand.bassa => 'down',
  };

  /// Trend description text
  String get trendText => switch (demand) {
    ZoneDemand.alta => 'Domanda in crescita — zona molto attiva ora',
    ZoneDemand.media => 'Domanda stabile — buona per consegne regolari',
    ZoneDemand.bassa => 'Domanda bassa — pochi ordini in questa zona',
  };

  /// Estimated rider count derived from ordersPerHour
  String get ridersEstimate => '${(ordersPerHour * 0.6).round()}';
}
