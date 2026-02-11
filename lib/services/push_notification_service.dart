import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../navigation/app_router.dart';

/// Top-level handler for background FCM messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Background FCM: ${message.notification?.title}');
}

/// Service for Firebase Cloud Messaging push notifications
class PushNotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static final _client = Supabase.instance.client;

  static String? get _riderId => _client.auth.currentUser?.id;

  // Notification channels
  static const _ordersChannel = AndroidNotificationChannel(
    'dloop_orders',
    'Ordini',
    description: 'Notifiche per nuovi ordini e aggiornamenti',
    importance: Importance.high,
    playSound: true,
  );

  static const _supportChannel = AndroidNotificationChannel(
    'dloop_support',
    'Supporto',
    description: 'Messaggi dal supporto dloop',
    importance: Importance.defaultImportance,
  );

  static const _earningsChannel = AndroidNotificationChannel(
    'dloop_earnings',
    'Guadagni',
    description: 'Guadagni e traguardi raggiunti',
    importance: Importance.low,
  );

  /// Initialize FCM and local notifications
  static Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('⚠️ Push notifications permission denied');
      return;
    }

    // Create Android notification channels
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_ordersChannel);
      await androidPlugin.createNotificationChannel(_supportChannel);
      await androidPlugin.createNotificationChannel(_earningsChannel);
    }

    // Initialize local notifications
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen to notification taps (when app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpen(initialMessage);
    }

    // Get and save FCM token
    await _saveFcmToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) => _saveFcmToken(token: token));
  }

  /// Handle foreground FCM messages — show local notification
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final channelId = _channelForType(message.data['type'] as String?);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == 'dloop_orders' ? 'Ordini' :
            channelId == 'dloop_support' ? 'Supporto' : 'Guadagni',
          icon: '@mipmap/ic_launcher',
          importance: channelId == 'dloop_orders' ? Importance.high : Importance.defaultImportance,
          priority: channelId == 'dloop_orders' ? Priority.high : Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Handle notification tap (background → opened)
  static void _handleNotificationOpen(RemoteMessage message) {
    _navigateByType(message.data);
  }

  /// Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateByType(data);
    } catch (_) {}
  }

  /// Navigate to the right screen based on notification type
  static void _navigateByType(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == null) {
      appRouter.go('/today/notifications');
      return;
    }

    if (type.startsWith('order') || type == 'new_order') {
      appRouter.go('/today');
    } else if (type == 'support_message') {
      appRouter.go('/you/support');
    } else {
      // earnings, achievements, system → notifications screen
      appRouter.go('/today/notifications');
    }
  }

  /// Determine notification channel based on type
  static String _channelForType(String? type) {
    if (type == null) return _ordersChannel.id;
    if (type.startsWith('order') || type == 'new_order') return _ordersChannel.id;
    if (type == 'support_message') return _supportChannel.id;
    return _earningsChannel.id;
  }

  /// Save FCM token to Supabase for server-side push
  static Future<void> _saveFcmToken({String? token}) async {
    final riderId = _riderId;
    if (riderId == null) return;

    try {
      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken == null) return;

      await _client.from('fcm_tokens').upsert({
        'rider_id': riderId,
        'token': fcmToken,
        'device_info': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'rider_id,token');

      print('✅ FCM token saved');
    } catch (e) {
      print('❌ Failed to save FCM token: $e');
    }
  }

  /// Remove FCM token on logout
  static Future<void> removeToken() async {
    final riderId = _riderId;
    if (riderId == null) return;

    try {
      final fcmToken = await _messaging.getToken();
      if (fcmToken == null) return;

      await _client
          .from('fcm_tokens')
          .delete()
          .eq('rider_id', riderId)
          .eq('token', fcmToken);
    } catch (e) {
      print('❌ Failed to remove FCM token: $e');
    }
  }
}
