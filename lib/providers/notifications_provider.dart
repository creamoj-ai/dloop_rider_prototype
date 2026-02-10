import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationsState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;

  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
  }) => NotificationsState(
    notifications: notifications ?? this.notifications,
    unreadCount: unreadCount ?? this.unreadCount,
    isLoading: isLoading ?? this.isLoading,
  );
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  StreamSubscription<List<AppNotification>>? _sub;

  NotificationsNotifier() : super(const NotificationsState(isLoading: true)) {
    _subscribe();
  }

  void _subscribe() {
    _sub?.cancel();
    _sub = NotificationService.subscribeToNotifications().listen(
      (notifications) {
        final unread = notifications.where((n) => !n.isRead).length;
        state = NotificationsState(
          notifications: notifications,
          unreadCount: unread,
        );
      },
      onError: (e) {
        print('❌ NotificationsNotifier stream error: $e');
        // Keep current state but stop loading
        state = state.copyWith(isLoading: false);
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    // Optimistic update
    state = NotificationsState(
      notifications: state.notifications.map((n) =>
        n.id == notificationId ? n.copyWith(isRead: true) : n
      ).toList(),
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );

    await NotificationService.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    // Optimistic update
    state = NotificationsState(
      notifications: state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
      unreadCount: 0,
    );

    await NotificationService.markAllAsRead();
  }

  void reload() {
    state = state.copyWith(isLoading: true);
    _sub?.cancel();
    _subscribe();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
  (ref) => NotificationsNotifier(),
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});
