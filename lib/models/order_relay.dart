/// Order Relay Status
enum OrderRelayStatus {
  pending,    // Relay created, not yet sent to dealer
  sent,       // WhatsApp/notification sent to dealer
  confirmed,  // Dealer confirmed preparation
  preparing,  // Dealer is preparing
  ready,      // Order ready for pickup
  pickedUp,   // Rider picked up from dealer
  cancelled,  // Relay cancelled
}

/// Payment Status for Stripe link
enum PaymentStatus { pending, sent, paid, failed }

/// Order Relay Model — tracks relay lifecycle from rider to dealer
class OrderRelay {
  final String id;
  final String orderId;
  final String riderId;
  final String dealerContactId;
  final OrderRelayStatus status;
  final String relayChannel; // 'in_app' | 'whatsapp' | 'phone'
  final String? dealerMessage;
  final String? dealerReply;
  final double? estimatedAmount;
  final double? actualAmount;
  final String? stripePaymentLink;
  final String? stripeSessionId;
  final PaymentStatus paymentStatus;
  final DateTime? relayedAt;
  final DateTime? confirmedAt;
  final DateTime? readyAt;
  final DateTime? pickedUpAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderRelay({
    required this.id,
    required this.orderId,
    required this.riderId,
    required this.dealerContactId,
    this.status = OrderRelayStatus.pending,
    this.relayChannel = 'in_app',
    this.dealerMessage,
    this.dealerReply,
    this.estimatedAmount,
    this.actualAmount,
    this.stripePaymentLink,
    this.stripeSessionId,
    this.paymentStatus = PaymentStatus.pending,
    this.relayedAt,
    this.confirmedAt,
    this.readyAt,
    this.pickedUpAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive =>
      status != OrderRelayStatus.cancelled &&
      status != OrderRelayStatus.pickedUp;

  bool get isPaid => paymentStatus == PaymentStatus.paid;

  bool get canCancel =>
      status == OrderRelayStatus.pending || status == OrderRelayStatus.sent;

  String get statusLabel {
    switch (status) {
      case OrderRelayStatus.pending:
        return 'In attesa';
      case OrderRelayStatus.sent:
        return 'Inviato';
      case OrderRelayStatus.confirmed:
        return 'Confermato';
      case OrderRelayStatus.preparing:
        return 'In preparazione';
      case OrderRelayStatus.ready:
        return 'Pronto';
      case OrderRelayStatus.pickedUp:
        return 'Ritirato';
      case OrderRelayStatus.cancelled:
        return 'Annullato';
    }
  }

  factory OrderRelay.fromJson(Map<String, dynamic> json) {
    double? _numOrNull(dynamic v) =>
        v != null ? double.tryParse(v.toString()) : null;

    final rawStatus = (json['status'] as String?) ?? 'pending';
    final statusName = rawStatus.replaceAll('_', '').toLowerCase();

    final rawPayment = (json['payment_status'] as String?) ?? 'pending';

    return OrderRelay(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      riderId: json['rider_id']?.toString() ?? '',
      dealerContactId: json['dealer_contact_id']?.toString() ?? '',
      status: OrderRelayStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == statusName,
        orElse: () => OrderRelayStatus.pending,
      ),
      relayChannel: json['relay_channel'] as String? ?? 'in_app',
      dealerMessage: json['dealer_message'] as String?,
      dealerReply: json['dealer_reply'] as String?,
      estimatedAmount: _numOrNull(json['estimated_amount']),
      actualAmount: _numOrNull(json['actual_amount']),
      stripePaymentLink: json['stripe_payment_link'] as String?,
      stripeSessionId: json['stripe_session_id'] as String?,
      paymentStatus: PaymentStatus.values.firstWhere(
        (s) => s.name == rawPayment,
        orElse: () => PaymentStatus.pending,
      ),
      relayedAt: json['relayed_at'] != null
          ? DateTime.tryParse(json['relayed_at'].toString())
          : null,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.tryParse(json['confirmed_at'].toString())
          : null,
      readyAt: json['ready_at'] != null
          ? DateTime.tryParse(json['ready_at'].toString())
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.tryParse(json['picked_up_at'].toString())
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'order_id': orderId,
        'rider_id': riderId,
        'dealer_contact_id': dealerContactId,
        'status': status.name == 'pickedUp' ? 'picked_up' : status.name,
        'relay_channel': relayChannel,
        'dealer_message': dealerMessage,
        'estimated_amount': estimatedAmount,
      };

  OrderRelay copyWith({
    OrderRelayStatus? status,
    String? dealerReply,
    double? actualAmount,
    String? stripePaymentLink,
    String? stripeSessionId,
    PaymentStatus? paymentStatus,
    DateTime? relayedAt,
    DateTime? confirmedAt,
    DateTime? readyAt,
    DateTime? pickedUpAt,
  }) {
    return OrderRelay(
      id: id,
      orderId: orderId,
      riderId: riderId,
      dealerContactId: dealerContactId,
      status: status ?? this.status,
      relayChannel: relayChannel,
      dealerMessage: dealerMessage,
      dealerReply: dealerReply ?? this.dealerReply,
      estimatedAmount: estimatedAmount,
      actualAmount: actualAmount ?? this.actualAmount,
      stripePaymentLink: stripePaymentLink ?? this.stripePaymentLink,
      stripeSessionId: stripeSessionId ?? this.stripeSessionId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      relayedAt: relayedAt ?? this.relayedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      readyAt: readyAt ?? this.readyAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
