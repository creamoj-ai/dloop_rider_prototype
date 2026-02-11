enum MarketOrderStatus { pending, accepted, delivering, delivered, cancelled }

enum OrderSource { bot, website, whatsapp, phone, app }

class MarketOrder {
  final String id;
  final String riderId;
  final String? productId;
  final String productName;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final MarketOrderStatus status;
  final OrderSource source;
  final String notes;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;

  const MarketOrder({
    required this.id,
    this.riderId = '',
    this.productId,
    required this.productName,
    required this.customerName,
    this.customerPhone = '',
    this.customerAddress = '',
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
    this.status = MarketOrderStatus.pending,
    this.source = OrderSource.app,
    this.notes = '',
    required this.createdAt,
    this.acceptedAt,
    this.deliveredAt,
  });

  bool get isActive =>
      status == MarketOrderStatus.pending ||
      status == MarketOrderStatus.accepted ||
      status == MarketOrderStatus.delivering;

  bool get isCompleted => status == MarketOrderStatus.delivered;
  bool get isCancelled => status == MarketOrderStatus.cancelled;

  String get statusLabel {
    switch (status) {
      case MarketOrderStatus.pending:
        return 'Nuovo';
      case MarketOrderStatus.accepted:
        return 'Accettato';
      case MarketOrderStatus.delivering:
        return 'In consegna';
      case MarketOrderStatus.delivered:
        return 'Consegnato';
      case MarketOrderStatus.cancelled:
        return 'Annullato';
    }
  }

  String get sourceLabel {
    switch (source) {
      case OrderSource.bot:
        return 'Bot AI';
      case OrderSource.website:
        return 'Sito web';
      case OrderSource.whatsapp:
        return 'WhatsApp';
      case OrderSource.phone:
        return 'Telefono';
      case OrderSource.app:
        return 'App';
    }
  }

  factory MarketOrder.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? 'pending';
    final rawSource = json['source'] as String? ?? 'app';

    return MarketOrder(
      id: json['id']?.toString() ?? '',
      riderId: json['rider_id']?.toString() ?? '',
      productId: json['product_id']?.toString(),
      productName: json['product_name'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      customerAddress: json['customer_address'] as String? ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0,
      status: MarketOrderStatus.values.firstWhere(
        (s) => s.name == rawStatus,
        orElse: () => MarketOrderStatus.pending,
      ),
      source: OrderSource.values.firstWhere(
        (s) => s.name == rawSource,
        orElse: () => OrderSource.app,
      ),
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'].toString())
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'status': status.name,
      'source': source.name,
      'notes': notes,
    };
  }
}
