import '../services/rush_hour_service.dart';
import 'rider.dart';

/// Order Status enum
enum OrderStatus {
  pending,    // In attesa di accettazione
  accepted,   // Accettato dal rider
  pickedUp,   // Ritirato dal ristorante
  delivered,  // Consegnato al cliente
  cancelled,  // Annullato
}

/// Order Model
/// Rappresenta un ordine/consegna con breakdown completo dei guadagni.
class Order {
  final String id;
  final String restaurantName;
  final String restaurantAddress;
  final String customerName;
  final String customerAddress;
  final double distanceKm;

  // Breakdown guadagni
  final double baseEarning;     // calcolato con distance tiers
  final double bonusEarning;    // Bonus performance
  final double tipAmount;       // Mancia cliente
  final double rushMultiplier;  // 1.0 normale, 2.0 rush hour
  final double holdCost;        // Costo attesa al ristorante
  final int holdMinutes;        // Minuti di attesa al ristorante
  final double minGuarantee;    // Minimo garantito per questa consegna

  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  // Rate per km default (usato quando non c'è RiderPricing)
  static const double defaultRatePerKm = 1.50;

  Order({
    required this.id,
    required this.restaurantName,
    this.restaurantAddress = '',
    this.customerName = '',
    required this.customerAddress,
    required this.distanceKm,
    required this.baseEarning,
    this.bonusEarning = 0,
    this.tipAmount = 0,
    this.rushMultiplier = 1.0,
    this.holdCost = 0,
    this.holdMinutes = 0,
    this.minGuarantee = 3.00,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  /// Calcola guadagno totale (con minimo garantito)
  double get totalEarning {
    final baseWithRush = baseEarning * rushMultiplier;
    final subtotal = baseWithRush + bonusEarning + tipAmount + holdCost;
    return subtotal < minGuarantee ? minGuarantee : subtotal;
  }

  /// Guadagno base con rush (senza bonus/tip/hold)
  double get baseWithRush => baseEarning * rushMultiplier;

  /// Bonus rush hour (la parte extra)
  double get rushBonus => rushMultiplier > 1
      ? baseEarning * (rushMultiplier - 1)
      : 0;

  /// È in rush hour?
  bool get isRushHour => rushMultiplier > 1;

  /// Il minimo garantito è stato applicato?
  bool get minGuaranteeApplied {
    final subtotal = baseWithRush + bonusEarning + tipAmount + holdCost;
    return subtotal < minGuarantee;
  }

  /// Tempo stimato consegna (minuti)
  int get estimatedMinutes => (distanceKm * 4).round();

  /// Fascia distanza
  String get distanceTier {
    if (distanceKm <= 2.0) return 'corta';
    if (distanceKm <= 5.0) return 'media';
    return 'lunga';
  }

  /// Factory per creare un nuovo ordine con calcolo automatico
  factory Order.create({
    required String id,
    required String restaurantName,
    String restaurantAddress = '',
    String customerName = '',
    required String customerAddress,
    required double distanceKm,
    double bonusEarning = 0,
    double tipAmount = 0,
    int holdMinutes = 0,
    RiderPricing? pricing,
  }) {
    final riderPricing = pricing ?? const RiderPricing();
    final multiplier = RushHourService.getCurrentMultiplier();
    final baseEarning = riderPricing.calculateBaseEarning(distanceKm);
    final holdCost = riderPricing.calculateHoldCost(holdMinutes);

    return Order(
      id: id,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
      customerName: customerName,
      customerAddress: customerAddress,
      distanceKm: distanceKm,
      baseEarning: baseEarning,
      bonusEarning: bonusEarning,
      tipAmount: tipAmount,
      rushMultiplier: multiplier,
      holdCost: holdCost,
      holdMinutes: holdMinutes,
      minGuarantee: riderPricing.minDeliveryFee,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  /// Copia con nuovo status
  Order copyWithStatus(OrderStatus newStatus) {
    return Order(
      id: id,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
      customerName: customerName,
      customerAddress: customerAddress,
      distanceKm: distanceKm,
      baseEarning: baseEarning,
      bonusEarning: bonusEarning,
      tipAmount: tipAmount,
      rushMultiplier: rushMultiplier,
      holdCost: holdCost,
      holdMinutes: holdMinutes,
      minGuarantee: minGuarantee,
      status: newStatus,
      createdAt: createdAt,
      acceptedAt: newStatus == OrderStatus.accepted ? DateTime.now() : acceptedAt,
      pickedUpAt: newStatus == OrderStatus.pickedUp ? DateTime.now() : pickedUpAt,
      deliveredAt: newStatus == OrderStatus.delivered ? DateTime.now() : deliveredAt,
    );
  }

  /// Aggiunge mancia
  Order addTip(double tip) {
    return Order(
      id: id,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
      customerName: customerName,
      customerAddress: customerAddress,
      distanceKm: distanceKm,
      baseEarning: baseEarning,
      bonusEarning: bonusEarning,
      tipAmount: tipAmount + tip,
      rushMultiplier: rushMultiplier,
      holdCost: holdCost,
      holdMinutes: holdMinutes,
      minGuarantee: minGuarantee,
      status: status,
      createdAt: createdAt,
      acceptedAt: acceptedAt,
      pickedUpAt: pickedUpAt,
      deliveredAt: deliveredAt,
    );
  }

  /// Aggiorna attesa (hold)
  Order updateHold(int minutes, RiderPricing pricing) {
    return Order(
      id: id,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
      customerName: customerName,
      customerAddress: customerAddress,
      distanceKm: distanceKm,
      baseEarning: baseEarning,
      bonusEarning: bonusEarning,
      tipAmount: tipAmount,
      rushMultiplier: rushMultiplier,
      holdCost: pricing.calculateHoldCost(minutes),
      holdMinutes: minutes,
      minGuarantee: minGuarantee,
      status: status,
      createdAt: createdAt,
      acceptedAt: acceptedAt,
      pickedUpAt: pickedUpAt,
      deliveredAt: deliveredAt,
    );
  }

  @override
  String toString() {
    return 'Order($id: $restaurantName -> $customerAddress, ${distanceKm}km, €$totalEarning)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_name': restaurantName,
      'restaurant_address': restaurantAddress,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'distance_km': distanceKm,
      'base_earning': baseEarning,
      'bonus_earning': bonusEarning,
      'tip_amount': tipAmount,
      'rush_multiplier': rushMultiplier,
      'hold_cost': holdCost,
      'hold_minutes': holdMinutes,
      'min_guarantee': minGuarantee,
      'distance_tier': distanceTier,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      restaurantName: json['restaurant_name'] as String,
      restaurantAddress: json['restaurant_address'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      customerAddress: json['customer_address'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
      baseEarning: (json['base_earning'] as num).toDouble(),
      bonusEarning: (json['bonus_earning'] as num?)?.toDouble() ?? 0,
      tipAmount: (json['tip_amount'] as num?)?.toDouble() ?? 0,
      rushMultiplier: (json['rush_multiplier'] as num?)?.toDouble() ?? 1.0,
      holdCost: (json['hold_cost'] as num?)?.toDouble() ?? 0,
      holdMinutes: (json['hold_minutes'] as int?) ?? 0,
      minGuarantee: (json['min_guarantee'] as num?)?.toDouble() ?? 3.00,
      status: OrderStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.parse(json['picked_up_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
    );
  }
}
