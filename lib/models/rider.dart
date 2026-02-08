/// Configurazione tariffe del rider
class RiderPricing {
  final double ratePerKm;        // €/km base (rider-configurable)
  final double minDeliveryFee;   // Minimo garantito per consegna
  final double holdCostPerMin;   // €/min attesa dopo soglia gratuita
  final int holdFreeMinutes;     // Minuti di attesa gratuiti

  // Distance tiers: sovrapprezzi per fasce di distanza
  final double shortDistanceMax;   // km soglia corta (es. 2km)
  final double mediumDistanceMax;  // km soglia media (es. 5km)
  final double longDistanceBonus;  // €/km extra oltre soglia media

  const RiderPricing({
    this.ratePerKm = 1.50,
    this.minDeliveryFee = 3.00,
    this.holdCostPerMin = 0.15,
    this.holdFreeMinutes = 5,
    this.shortDistanceMax = 2.0,
    this.mediumDistanceMax = 5.0,
    this.longDistanceBonus = 0.50,
  });

  /// Calcola il compenso base per distanza con tiers
  double calculateBaseEarning(double distanceKm) {
    if (distanceKm <= shortDistanceMax) {
      // Corta: tariffa base
      final earning = distanceKm * ratePerKm;
      return earning < minDeliveryFee ? minDeliveryFee : earning;
    } else if (distanceKm <= mediumDistanceMax) {
      // Media: tariffa base
      return distanceKm * ratePerKm;
    } else {
      // Lunga: tariffa base + bonus/km extra
      final baseKmEarning = distanceKm * ratePerKm;
      final extraKm = distanceKm - mediumDistanceMax;
      return baseKmEarning + (extraKm * longDistanceBonus);
    }
  }

  /// Calcola costo attesa
  double calculateHoldCost(int waitMinutes) {
    if (waitMinutes <= holdFreeMinutes) return 0;
    return (waitMinutes - holdFreeMinutes) * holdCostPerMin;
  }

  RiderPricing copyWith({
    double? ratePerKm,
    double? minDeliveryFee,
    double? holdCostPerMin,
    int? holdFreeMinutes,
    double? shortDistanceMax,
    double? mediumDistanceMax,
    double? longDistanceBonus,
  }) {
    return RiderPricing(
      ratePerKm: ratePerKm ?? this.ratePerKm,
      minDeliveryFee: minDeliveryFee ?? this.minDeliveryFee,
      holdCostPerMin: holdCostPerMin ?? this.holdCostPerMin,
      holdFreeMinutes: holdFreeMinutes ?? this.holdFreeMinutes,
      shortDistanceMax: shortDistanceMax ?? this.shortDistanceMax,
      mediumDistanceMax: mediumDistanceMax ?? this.mediumDistanceMax,
      longDistanceBonus: longDistanceBonus ?? this.longDistanceBonus,
    );
  }

  Map<String, dynamic> toJson() => {
    'rate_per_km': ratePerKm,
    'min_delivery_fee': minDeliveryFee,
    'hold_cost_per_min': holdCostPerMin,
    'hold_free_minutes': holdFreeMinutes,
    'short_distance_max': shortDistanceMax,
    'medium_distance_max': mediumDistanceMax,
    'long_distance_bonus': longDistanceBonus,
  };

  factory RiderPricing.fromJson(Map<String, dynamic> json) => RiderPricing(
    ratePerKm: (json['rate_per_km'] as num?)?.toDouble() ?? 1.50,
    minDeliveryFee: (json['min_delivery_fee'] as num?)?.toDouble() ?? 3.00,
    holdCostPerMin: (json['hold_cost_per_min'] as num?)?.toDouble() ?? 0.15,
    holdFreeMinutes: (json['hold_free_minutes'] as int?) ?? 5,
    shortDistanceMax: (json['short_distance_max'] as num?)?.toDouble() ?? 2.0,
    mediumDistanceMax: (json['medium_distance_max'] as num?)?.toDouble() ?? 5.0,
    longDistanceBonus: (json['long_distance_bonus'] as num?)?.toDouble() ?? 0.50,
  );
}

class Rider {
  final String name;
  final String email;
  final String avatarUrl;
  final int level;
  final int currentXp;
  final int xpToNextLevel;
  final int streak;
  final int totalOrders;
  final double totalEarnings;
  final double totalKm;
  final double avgRating;
  final DateTime memberSince;
  final RiderPricing pricing;

  const Rider({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.level,
    required this.currentXp,
    required this.xpToNextLevel,
    required this.streak,
    required this.totalOrders,
    required this.totalEarnings,
    required this.totalKm,
    required this.avgRating,
    required this.memberSince,
    this.pricing = const RiderPricing(),
  });

  Rider copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    int? level,
    int? currentXp,
    int? xpToNextLevel,
    int? streak,
    int? totalOrders,
    double? totalEarnings,
    double? totalKm,
    double? avgRating,
    DateTime? memberSince,
    RiderPricing? pricing,
  }) {
    return Rider(
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      streak: streak ?? this.streak,
      totalOrders: totalOrders ?? this.totalOrders,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalKm: totalKm ?? this.totalKm,
      avgRating: avgRating ?? this.avgRating,
      memberSince: memberSince ?? this.memberSince,
      pricing: pricing ?? this.pricing,
    );
  }
}
