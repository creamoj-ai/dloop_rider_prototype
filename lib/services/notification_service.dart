import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../utils/logger.dart';
import '../utils/retry.dart';

class NotificationService {
  static final _client = Supabase.instance.client;

  static String? get _riderId => _client.auth.currentUser?.id;

  /// Fetch notifications for the current rider (with retry)
  static Future<List<AppNotification>> getNotifications({int limit = 50}) async {
    final riderId = _riderId;
    if (riderId == null) return [];

    return retry(() async {
      final response = await _client
          .from('notifications')
          .select()
          .eq('rider_id', riderId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    }, onRetry: (attempt, e) {
      dlog('⚡ NotificationService.getNotifications retry $attempt: $e');
    });
  }

  /// Get unread count
  static Future<int> getUnreadCount() async {
    final riderId = _riderId;
    if (riderId == null) return 0;

    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('rider_id', riderId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Mark a single notification as read
  static Future<void> markAsRead(String notificationId) async {
    final riderId = _riderId;
    if (riderId == null) return;

    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('rider_id', riderId);
    } catch (e) {
      dlog('❌ NotificationService.markAsRead failed: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    final riderId = _riderId;
    if (riderId == null) return;

    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('rider_id', riderId)
          .eq('is_read', false);
    } catch (e) {
      dlog('❌ NotificationService.markAllAsRead failed: $e');
    }
  }

  /// Subscribe to real-time notification updates (with auto-reconnect)
  static Stream<List<AppNotification>> subscribeToNotifications() {
    final riderId = _riderId;
    if (riderId == null) {
      return Stream.value([]);
    }

    return retryStream(
      () => _client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('rider_id', riderId)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => AppNotification.fromJson(json)).toList()),
      onReconnect: (attempt, e) {
        dlog('⚡ NotificationService.subscribeToNotifications reconnect $attempt: $e');
      },
    );
  }
}
