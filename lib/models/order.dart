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

  // Hybrid dispatch fields
  final String? assignedRiderId;
  final String? zoneId;
  final String source;
  final DateTime? priorityExpiresAt;
  final String? dealerContactId;
  final String? dealerPlatformId;

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
    this.assignedRiderId,
    this.zoneId,
    this.source = 'manual',
    this.priorityExpiresAt,
    this.dealerContactId,
    this.dealerPlatformId,
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
      assignedRiderId: assignedRiderId,
      zoneId: zoneId,
      source: source,
      priorityExpiresAt: priorityExpiresAt,
      dealerContactId: dealerContactId,
      dealerPlatformId: dealerPlatformId,
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
      assignedRiderId: assignedRiderId,
      zoneId: zoneId,
      source: source,
      priorityExpiresAt: priorityExpiresAt,
      dealerContactId: dealerContactId,
      dealerPlatformId: dealerPlatformId,
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
      assignedRiderId: assignedRiderId,
      zoneId: zoneId,
      source: source,
      priorityExpiresAt: priorityExpiresAt,
      dealerContactId: dealerContactId,
      dealerPlatformId: dealerPlatformId,
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
      'assigned_rider_id': assignedRiderId,
      'zone_id': zoneId,
      'source': source,
      'priority_expires_at': priorityExpiresAt?.toIso8601String(),
      'dealer_contact_id': dealerContactId,
      'dealer_platform_id': dealerPlatformId,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    // Helper: Supabase may return DECIMAL as String
    double _num(dynamic v, [double fallback = 0]) =>
        double.tryParse(v?.toString() ?? '') ?? fallback;

    int _int(dynamic v, [int fallback = 0]) =>
        int.tryParse(v?.toString() ?? '') ?? fallback;

    // DB uses pickup_address / delivery_address; model uses restaurant_ / customer_
    final pickupAddr = json['pickup_address'] as String?;
    final restaurantName = json['restaurant_name'] as String? ??
        pickupAddr?.split(',').first ?? 'Ordine';

    // Map status — DB uses 'picked_up', Dart enum uses 'pickedUp'
    final rawStatus = (json['status'] as String?) ?? 'pending';
    final statusName = rawStatus.replaceAll('_', '').toLowerCase();

    return Order(
      id: json['id']?.toString() ?? '',
      restaurantName: restaurantName,
      restaurantAddress: json['restaurant_address'] as String? ?? pickupAddr ?? '',
      customerName: json['customer_name'] as String? ?? '',
      customerAddress: json['customer_address'] as String? ?? json['delivery_address'] as String? ?? '',
      distanceKm: _num(json['distance_km']),
      baseEarning: _num(json['base_earning'] ?? json['base_earnings']),
      bonusEarning: _num(json['bonus_earning'] ?? json['bonus_earnings']),
      tipAmount: _num(json['tip_amount']),
      rushMultiplier: _num(json['rush_multiplier'], 1.0),
      holdCost: _num(json['hold_cost']),
      holdMinutes: _int(json['hold_minutes']),
      minGuarantee: _num(json['min_guarantee'], 3.0),
      status: OrderStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == statusName,
        orElse: () => OrderStatus.values.firstWhere(
          (s) => s.name == rawStatus,
          orElse: () => OrderStatus.pending,
        ),
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'] as String)
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.tryParse(json['picked_up_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'] as String)
          : null,
      assignedRiderId: json['assigned_rider_id']?.toString(),
      zoneId: json['zone_id']?.toString(),
      source: json['source'] as String? ?? 'manual',
      priorityExpiresAt: json['priority_expires_at'] != null
          ? DateTime.tryParse(json['priority_expires_at'].toString())
          : null,
      dealerContactId: json['dealer_contact_id']?.toString(),
      dealerPlatformId: json['dealer_platform_id']?.toString(),
    );
  }

  /// Is this a broadcast order (no assigned rider, expired priority)?
  bool get isBroadcast =>
      assignedRiderId == null &&
      priorityExpiresAt != null &&
      priorityExpiresAt!.isBefore(DateTime.now());
}
