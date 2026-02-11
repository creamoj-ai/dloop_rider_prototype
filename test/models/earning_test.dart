import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/earning.dart';

void main() {
  group('EarningType enum', () {
    test('has all expected values', () {
      expect(EarningType.values, [
        EarningType.delivery,
        EarningType.network,
        EarningType.market,
      ]);
    });
  });

  group('EarningStatus enum', () {
    test('has all expected values', () {
      expect(EarningStatus.values, [
        EarningStatus.completed,
        EarningStatus.pending,
        EarningStatus.cancelled,
      ]);
    });
  });

  group('Earning.fromJson', () {
    test('with complete data', () {
      final json = {
        'id': 'earn-1',
        'type': 'order_earning',
        'description': 'Consegna completata',
        'amount': 8.50,
        'processed_at': '2026-02-10T14:30:00Z',
        'status': 'completed',
        'order_id': 'order-123',
      };

      final earning = Earning.fromJson(json);

      expect(earning.id, 'earn-1');
      expect(earning.type, EarningType.delivery);
      expect(earning.description, 'Consegna completata');
      expect(earning.amount, 8.50);
      expect(earning.status, EarningStatus.completed);
      expect(earning.orderId, 'order-123');
    });

    test('with null/missing fields uses defaults', () {
      final json = <String, dynamic>{
        'id': null,
      };

      final earning = Earning.fromJson(json);

      expect(earning.id, '');
      expect(earning.type, EarningType.delivery);
      expect(earning.description, '');
      expect(earning.amount, 0.0);
      expect(earning.status, EarningStatus.completed);
      expect(earning.orderId, isNull);
    });

    test('maps DB type order_earning to EarningType.delivery', () {
      final json = {
        'id': 'e1',
        'type': 'order_earning',
        'description': '',
        'amount': 5.0,
        'processed_at': '2026-02-10T12:00:00Z',
        'status': 'completed',
      };

      expect(Earning.fromJson(json).type, EarningType.delivery);
    });

    test('maps DB type commission to EarningType.network', () {
      final json = {
        'id': 'e2',
        'type': 'commission',
        'description': '',
        'amount': 3.0,
        'processed_at': '2026-02-10T12:00:00Z',
        'status': 'completed',
      };

      expect(Earning.fromJson(json).type, EarningType.network);
    });

    test('maps DB type market_sale to EarningType.market', () {
      final json = {
        'id': 'e3',
        'type': 'market_sale',
        'description': '',
        'amount': 12.0,
        'processed_at': '2026-02-10T12:00:00Z',
        'status': 'completed',
      };

      expect(Earning.fromJson(json).type, EarningType.market);
    });

    test('maps DB type bonus to EarningType.network', () {
      final json = {
        'id': 'e4',
        'type': 'bonus',
        'description': '',
        'amount': 5.0,
        'processed_at': '2026-02-10T12:00:00Z',
        'status': 'completed',
      };

      expect(Earning.fromJson(json).type, EarningType.network);
    });

    test('maps DB type tip to EarningType.delivery', () {
      final json = {
        'id': 'e5',
        'type': 'tip',
        'description': '',
        'amount': 2.0,
        'processed_at': '2026-02-10T12:00:00Z',
        'status': 'completed',
      };

      expect(Earning.fromJson(json).type, EarningType.delivery);
    });

    test('maps unknown DB type to EarningType.delivery', () {
      final json = {
        'id': 'e6',
        'type': 'unknown_type',
        'description': '',
        'amount': 1.0,
        'processed_at': '2026-02-10T12:00:00Z',
        'status': 'completed',
      };

      expect(Earning.fromJson(json).type, EarningType.delivery);
    });

    test('with amount as string', () {
      final json = {
        'id': 'e7',
        'type': 'order_earning',
        'description': '',
        'amount': '15.75',
        'processed_at': '2026-02-10T12:00:00Z',
        'status': 'completed',
      };

      expect(Earning.fromJson(json).amount, 15.75);
    });

    test('with unknown status falls back to completed', () {
      final json = {
        'id': 'e8',
        'type': 'order_earning',
        'description': '',
        'amount': 5.0,
        'processed_at': '2026-02-10T12:00:00Z',
        'status': 'unknown',
      };

      expect(Earning.fromJson(json).status, EarningStatus.completed);
    });

    test('uses date_time column as fallback for processed_at', () {
      final json = {
        'id': 'e9',
        'type': 'order_earning',
        'description': '',
        'amount': 5.0,
        'date_time': '2026-02-10T15:00:00Z',
        'status': 'completed',
      };

      final earning = Earning.fromJson(json);
      expect(earning.dateTime.hour, 15);
    });
  });

  group('Earning.toJson', () {
    test('serializes correctly with order_id', () {
      final earning = Earning(
        id: 'tj-1',
        type: EarningType.delivery,
        description: 'Test delivery',
        amount: 8.50,
        dateTime: DateTime(2026, 2, 10, 14, 30),
        status: EarningStatus.completed,
        orderId: 'order-789',
      );

      final json = earning.toJson();

      expect(json['type'], 'order_earning');
      expect(json['description'], 'Test delivery');
      expect(json['amount'], 8.50);
      expect(json['processed_at'], contains('2026-02-10'));
      expect(json['status'], 'completed');
      expect(json['order_id'], 'order-789');
    });

    test('excludes order_id when null', () {
      final earning = Earning(
        id: 'tj-2',
        type: EarningType.network,
        description: 'Commission',
        amount: 3.0,
        dateTime: DateTime.now(),
        status: EarningStatus.completed,
        orderId: null,
      );

      final json = earning.toJson();
      expect(json.containsKey('order_id'), false);
      expect(json['type'], 'commission');
    });

    test('excludes order_id when empty', () {
      final earning = Earning(
        id: 'tj-3',
        type: EarningType.market,
        description: 'Sale',
        amount: 12.0,
        dateTime: DateTime.now(),
        status: EarningStatus.pending,
        orderId: '',
      );

      final json = earning.toJson();
      expect(json.containsKey('order_id'), false);
      expect(json['type'], 'market_sale');
      expect(json['status'], 'pending');
    });
  });
}
