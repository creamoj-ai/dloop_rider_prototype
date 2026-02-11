import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/notification.dart';

void main() {
  group('NotificationType enum', () {
    test('has all expected values', () {
      expect(NotificationType.values.length, 9);
      expect(NotificationType.values, contains(NotificationType.newOrder));
      expect(NotificationType.values, contains(NotificationType.orderAccepted));
      expect(NotificationType.values, contains(NotificationType.orderPickedUp));
      expect(NotificationType.values, contains(NotificationType.orderDelivered));
      expect(NotificationType.values, contains(NotificationType.orderCancelled));
      expect(NotificationType.values, contains(NotificationType.newEarning));
      expect(NotificationType.values, contains(NotificationType.dailyTargetReached));
      expect(NotificationType.values, contains(NotificationType.achievement));
      expect(NotificationType.values, contains(NotificationType.system));
    });
  });

  group('AppNotification.fromJson', () {
    test('with complete data', () {
      final json = {
        'id': 'notif-001',
        'rider_id': 'rider-abc',
        'type': 'new_order',
        'title': 'Nuovo ordine!',
        'body': 'Hai un nuovo ordine da ritirare',
        'data': {'order_id': 'order-123'},
        'is_read': false,
        'created_at': '2026-02-10T14:00:00Z',
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 'notif-001');
      expect(notif.riderId, 'rider-abc');
      expect(notif.type, NotificationType.newOrder);
      expect(notif.title, 'Nuovo ordine!');
      expect(notif.body, 'Hai un nuovo ordine da ritirare');
      expect(notif.data['order_id'], 'order-123');
      expect(notif.isRead, false);
      expect(notif.createdAt.year, 2026);
    });

    test('with missing fields uses defaults', () {
      final json = <String, dynamic>{
        'id': null,
        'rider_id': null,
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, '');
      expect(notif.riderId, '');
      expect(notif.type, NotificationType.system);
      expect(notif.title, '');
      expect(notif.body, '');
      expect(notif.data, isEmpty);
      expect(notif.isRead, false);
    });

    test('with data not being a Map defaults to empty', () {
      final json = {
        'id': '1',
        'rider_id': 'r1',
        'type': 'system',
        'title': 'Test',
        'data': 'not a map',
        'created_at': '2026-02-10T12:00:00Z',
      };

      final notif = AppNotification.fromJson(json);
      expect(notif.data, isEmpty);
    });
  });

  group('AppNotification type mapping', () {
    final baseJson = {
      'id': '1',
      'rider_id': 'r1',
      'title': 'Test',
      'created_at': '2026-02-10T12:00:00Z',
    };

    test('new_order maps to newOrder', () {
      final json = Map<String, dynamic>.from(baseJson)..['type'] = 'new_order';
      expect(AppNotification.fromJson(json).type, NotificationType.newOrder);
    });

    test('order_accepted maps to orderAccepted', () {
      final json = Map<String, dynamic>.from(baseJson)..['type'] = 'order_accepted';
      expect(AppNotification.fromJson(json).type, NotificationType.orderAccepted);
    });

    test('order_picked_up maps to orderPickedUp', () {
      final json = Map<String, dynamic>.from(baseJson)..['type'] = 'order_picked_up';
      expect(AppNotification.fromJson(json).type, NotificationType.orderPickedUp);
    });

    test('order_delivered maps to orderDelivered', () {
      final json = Map<String, dynamic>.from(baseJson)..['type'] = 'order_delivered';
      expect(AppNotification.fromJson(json).type, NotificationType.orderDelivered);
    });

    test('order_cancelled maps to orderCancelled', () {
      final json = Map<String, dynamic>.from(baseJson)..['type'] = 'order_cancelled';
      expect(AppNotification.fromJson(json).type, NotificationType.orderCancelled);
    });

    test('new_earning maps to newEarning', () {
      final json = Map<String, dynamic>.from(baseJson)..['type'] = 'new_earning';
      expect(AppNotification.fromJson(json).type, NotificationType.newEarning);
    });

    test('daily_target_reached maps to dailyTargetReached', () {
      final json = Map<String, dynamic>.from(baseJson)..['type'] = 'daily_target_reached';
      expect(AppNotification.fromJson(json).type, NotificationType.dailyTargetReached);
    });

    test('achievement maps to achievement', () {
      final json = Map<String, dynamic>.from(baseJson)..['type'] = 'achievement';
      expect(AppNotification.fromJson(json).type, NotificationType.achievement);
    });

    test('unknown type maps to system', () {
      final json = Map<String, dynamic>.from(baseJson)..['type'] = 'unknown_type';
      expect(AppNotification.fromJson(json).type, NotificationType.system);
    });
  });

  group('AppNotification.copyWith', () {
    test('changes isRead to true', () {
      final notif = AppNotification(
        id: 'notif-1',
        riderId: 'rider-1',
        type: NotificationType.newOrder,
        title: 'New Order',
        body: 'You have a new order',
        isRead: false,
        createdAt: DateTime(2026, 2, 10),
      );

      final read = notif.copyWith(isRead: true);

      expect(read.isRead, true);
      expect(read.id, notif.id);
      expect(read.type, notif.type);
      expect(read.title, notif.title);
      expect(read.body, notif.body);
    });

    test('without parameters keeps original isRead', () {
      final notif = AppNotification(
        id: 'notif-2',
        riderId: 'rider-1',
        type: NotificationType.system,
        title: 'System',
        isRead: false,
        createdAt: DateTime(2026, 2, 10),
      );

      final copy = notif.copyWith();
      expect(copy.isRead, false);
    });
  });

  group('AppNotification.toJson', () {
    test('serializes type to DB format', () {
      final notif = AppNotification(
        id: 'tj-1',
        riderId: 'rider-1',
        type: NotificationType.newOrder,
        title: 'Nuovo ordine',
        body: 'Dettagli ordine',
        data: const {'order_id': 'o1'},
        isRead: false,
        createdAt: DateTime(2026, 2, 10),
      );

      final json = notif.toJson();

      expect(json['type'], 'new_order');
      expect(json['title'], 'Nuovo ordine');
      expect(json['body'], 'Dettagli ordine');
      expect(json['data'], {'order_id': 'o1'});
      expect(json['is_read'], false);
    });

    test('all NotificationType values have DB mapping', () {
      for (final type in NotificationType.values) {
        final notif = AppNotification(
          id: 'test',
          riderId: 'r1',
          type: type,
          title: 'Test',
          createdAt: DateTime(2026, 2, 10),
        );
        final json = notif.toJson();
        expect(json['type'], isA<String>());
        expect((json['type'] as String).isNotEmpty, true);
      }
    });

    test('bidirectional mapping (toJson -> fromJson roundtrip)', () {
      for (final type in NotificationType.values) {
        final original = AppNotification(
          id: 'rt',
          riderId: 'r1',
          type: type,
          title: 'Test',
          createdAt: DateTime(2026, 2, 10),
        );

        final json = original.toJson();
        final restored = AppNotification.fromJson({
          ...json,
          'id': 'rt',
          'rider_id': 'r1',
          'created_at': '2026-02-10T00:00:00.000',
        });

        expect(restored.type, type,
            reason: 'Roundtrip failed for $type');
      }
    });
  });
}
