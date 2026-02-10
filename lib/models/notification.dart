enum NotificationType {
  newOrder,
  orderAccepted,
  orderPickedUp,
  orderDelivered,
  orderCancelled,
  newEarning,
  dailyTargetReached,
  achievement,
  system,
}

class AppNotification {
  final String id;
  final String riderId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.riderId,
    required this.type,
    required this.title,
    this.body = '',
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    riderId: riderId,
    type: type,
    title: title,
    body: body,
    data: data,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'type': _typeToDb(type),
    'title': title,
    'body': body,
    'data': data,
    'is_read': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id']?.toString() ?? '',
    riderId: json['rider_id']?.toString() ?? '',
    type: _typeFromDb(json['type'] as String? ?? ''),
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    data: json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : const {},
    isRead: json['is_read'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  static String _typeToDb(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder: return 'new_order';
      case NotificationType.orderAccepted: return 'order_accepted';
      case NotificationType.orderPickedUp: return 'order_picked_up';
      case NotificationType.orderDelivered: return 'order_delivered';
      case NotificationType.orderCancelled: return 'order_cancelled';
      case NotificationType.newEarning: return 'new_earning';
      case NotificationType.dailyTargetReached: return 'daily_target_reached';
      case NotificationType.achievement: return 'achievement';
      case NotificationType.system: return 'system';
    }
  }

  static NotificationType _typeFromDb(String dbType) {
    switch (dbType) {
      case 'new_order': return NotificationType.newOrder;
      case 'order_accepted': return NotificationType.orderAccepted;
      case 'order_picked_up': return NotificationType.orderPickedUp;
      case 'order_delivered': return NotificationType.orderDelivered;
      case 'order_cancelled': return NotificationType.orderCancelled;
      case 'new_earning': return NotificationType.newEarning;
      case 'daily_target_reached': return NotificationType.dailyTargetReached;
      case 'achievement': return NotificationType.achievement;
      default: return NotificationType.system;
    }
  }
}
