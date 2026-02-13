import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/order_relay.dart';

void main() {
  group('OrderRelayStatus enum', () {
    test('has all expected values', () {
      expect(OrderRelayStatus.values, [
        OrderRelayStatus.pending,
        OrderRelayStatus.sent,
        OrderRelayStatus.confirmed,
        OrderRelayStatus.preparing,
        OrderRelayStatus.ready,
        OrderRelayStatus.pickedUp,
        OrderRelayStatus.cancelled,
      ]);
    });
  });

  group('PaymentStatus enum', () {
    test('has all expected values', () {
      expect(PaymentStatus.values, [
        PaymentStatus.pending,
        PaymentStatus.sent,
        PaymentStatus.paid,
        PaymentStatus.failed,
      ]);
    });
  });

  group('OrderRelay.fromJson', () {
    test('with complete data', () {
      final json = {
        'id': 'relay-1',
        'order_id': 'order-1',
        'rider_id': 'rider-1',
        'dealer_contact_id': 'dealer-1',
        'status': 'confirmed',
        'relay_channel': 'whatsapp',
        'dealer_message': 'Prepara subito',
        'dealer_reply': 'OK confermato',
        'estimated_amount': 12.50,
        'actual_amount': 13.00,
        'stripe_payment_link': 'https://pay.stripe.com/test_123',
        'stripe_session_id': 'sess_123',
        'payment_status': 'paid',
        'relayed_at': '2026-02-13T10:00:00Z',
        'confirmed_at': '2026-02-13T10:05:00Z',
        'ready_at': '2026-02-13T10:20:00Z',
        'picked_up_at': null,
        'created_at': '2026-02-13T09:55:00Z',
        'updated_at': '2026-02-13T10:05:00Z',
      };

      final relay = OrderRelay.fromJson(json);

      expect(relay.id, 'relay-1');
      expect(relay.orderId, 'order-1');
      expect(relay.riderId, 'rider-1');
      expect(relay.dealerContactId, 'dealer-1');
      expect(relay.status, OrderRelayStatus.confirmed);
      expect(relay.relayChannel, 'whatsapp');
      expect(relay.dealerMessage, 'Prepara subito');
      expect(relay.dealerReply, 'OK confermato');
      expect(relay.estimatedAmount, 12.50);
      expect(relay.actualAmount, 13.00);
      expect(relay.stripePaymentLink, 'https://pay.stripe.com/test_123');
      expect(relay.stripeSessionId, 'sess_123');
      expect(relay.paymentStatus, PaymentStatus.paid);
      expect(relay.relayedAt, isNotNull);
      expect(relay.confirmedAt, isNotNull);
      expect(relay.readyAt, isNotNull);
      expect(relay.pickedUpAt, isNull);
    });

    test('with minimal data', () {
      final json = {
        'id': 'relay-2',
        'order_id': 'order-2',
        'rider_id': 'rider-2',
        'dealer_contact_id': 'dealer-2',
        'created_at': '2026-02-13T12:00:00Z',
        'updated_at': '2026-02-13T12:00:00Z',
      };

      final relay = OrderRelay.fromJson(json);

      expect(relay.id, 'relay-2');
      expect(relay.status, OrderRelayStatus.pending);
      expect(relay.relayChannel, 'in_app');
      expect(relay.paymentStatus, PaymentStatus.pending);
      expect(relay.dealerMessage, isNull);
      expect(relay.estimatedAmount, isNull);
      expect(relay.stripePaymentLink, isNull);
    });

    test('handles picked_up status with underscore', () {
      final json = {
        'id': 'relay-3',
        'order_id': 'o3',
        'rider_id': 'r3',
        'dealer_contact_id': 'd3',
        'status': 'picked_up',
        'created_at': '2026-02-13T12:00:00Z',
        'updated_at': '2026-02-13T12:00:00Z',
      };

      final relay = OrderRelay.fromJson(json);
      expect(relay.status, OrderRelayStatus.pickedUp);
    });

    test('defaults to pending for unknown status', () {
      final json = {
        'id': 'relay-4',
        'order_id': 'o4',
        'rider_id': 'r4',
        'dealer_contact_id': 'd4',
        'status': 'unknown_value',
        'created_at': '2026-02-13T12:00:00Z',
        'updated_at': '2026-02-13T12:00:00Z',
      };

      final relay = OrderRelay.fromJson(json);
      expect(relay.status, OrderRelayStatus.pending);
    });

    test('handles null/missing fields gracefully', () {
      final json = <String, dynamic>{};

      final relay = OrderRelay.fromJson(json);
      expect(relay.id, '');
      expect(relay.orderId, '');
      expect(relay.status, OrderRelayStatus.pending);
      expect(relay.paymentStatus, PaymentStatus.pending);
    });
  });

  group('OrderRelay computed properties', () {
    OrderRelay makeRelay({
      OrderRelayStatus status = OrderRelayStatus.pending,
      PaymentStatus paymentStatus = PaymentStatus.pending,
    }) {
      return OrderRelay(
        id: 'r1',
        orderId: 'o1',
        riderId: 'rid1',
        dealerContactId: 'd1',
        status: status,
        paymentStatus: paymentStatus,
        createdAt: DateTime(2026, 2, 13),
        updatedAt: DateTime(2026, 2, 13),
      );
    }

    test('isActive returns true for active statuses', () {
      expect(makeRelay(status: OrderRelayStatus.pending).isActive, isTrue);
      expect(makeRelay(status: OrderRelayStatus.sent).isActive, isTrue);
      expect(makeRelay(status: OrderRelayStatus.confirmed).isActive, isTrue);
      expect(makeRelay(status: OrderRelayStatus.preparing).isActive, isTrue);
      expect(makeRelay(status: OrderRelayStatus.ready).isActive, isTrue);
    });

    test('isActive returns false for terminal statuses', () {
      expect(makeRelay(status: OrderRelayStatus.cancelled).isActive, isFalse);
      expect(makeRelay(status: OrderRelayStatus.pickedUp).isActive, isFalse);
    });

    test('isPaid returns true only when paid', () {
      expect(makeRelay(paymentStatus: PaymentStatus.paid).isPaid, isTrue);
      expect(makeRelay(paymentStatus: PaymentStatus.pending).isPaid, isFalse);
      expect(makeRelay(paymentStatus: PaymentStatus.sent).isPaid, isFalse);
      expect(makeRelay(paymentStatus: PaymentStatus.failed).isPaid, isFalse);
    });

    test('canCancel only for pending/sent', () {
      expect(makeRelay(status: OrderRelayStatus.pending).canCancel, isTrue);
      expect(makeRelay(status: OrderRelayStatus.sent).canCancel, isTrue);
      expect(makeRelay(status: OrderRelayStatus.confirmed).canCancel, isFalse);
      expect(makeRelay(status: OrderRelayStatus.ready).canCancel, isFalse);
    });

    test('statusLabel returns Italian labels', () {
      expect(makeRelay(status: OrderRelayStatus.pending).statusLabel, 'In attesa');
      expect(makeRelay(status: OrderRelayStatus.sent).statusLabel, 'Inviato');
      expect(makeRelay(status: OrderRelayStatus.confirmed).statusLabel, 'Confermato');
      expect(makeRelay(status: OrderRelayStatus.preparing).statusLabel, 'In preparazione');
      expect(makeRelay(status: OrderRelayStatus.ready).statusLabel, 'Pronto');
      expect(makeRelay(status: OrderRelayStatus.pickedUp).statusLabel, 'Ritirato');
      expect(makeRelay(status: OrderRelayStatus.cancelled).statusLabel, 'Annullato');
    });
  });

  group('OrderRelay.copyWith', () {
    test('preserves unchanged fields', () {
      final original = OrderRelay(
        id: 'r1',
        orderId: 'o1',
        riderId: 'rid1',
        dealerContactId: 'd1',
        status: OrderRelayStatus.pending,
        estimatedAmount: 10.0,
        createdAt: DateTime(2026, 2, 13),
        updatedAt: DateTime(2026, 2, 13),
      );

      final updated = original.copyWith(status: OrderRelayStatus.confirmed);

      expect(updated.id, 'r1');
      expect(updated.orderId, 'o1');
      expect(updated.dealerContactId, 'd1');
      expect(updated.estimatedAmount, 10.0);
      expect(updated.status, OrderRelayStatus.confirmed);
    });

    test('updates multiple fields', () {
      final original = OrderRelay(
        id: 'r1',
        orderId: 'o1',
        riderId: 'rid1',
        dealerContactId: 'd1',
        createdAt: DateTime(2026, 2, 13),
        updatedAt: DateTime(2026, 2, 13),
      );

      final updated = original.copyWith(
        status: OrderRelayStatus.ready,
        paymentStatus: PaymentStatus.paid,
        actualAmount: 15.00,
      );

      expect(updated.status, OrderRelayStatus.ready);
      expect(updated.paymentStatus, PaymentStatus.paid);
      expect(updated.actualAmount, 15.00);
    });
  });

  group('OrderRelay.toInsertJson', () {
    test('produces correct format', () {
      final relay = OrderRelay(
        id: 'r1',
        orderId: 'o1',
        riderId: 'rid1',
        dealerContactId: 'd1',
        status: OrderRelayStatus.pending,
        relayChannel: 'whatsapp',
        dealerMessage: 'Test message',
        estimatedAmount: 8.50,
        createdAt: DateTime(2026, 2, 13),
        updatedAt: DateTime(2026, 2, 13),
      );

      final json = relay.toInsertJson();

      expect(json['order_id'], 'o1');
      expect(json['rider_id'], 'rid1');
      expect(json['dealer_contact_id'], 'd1');
      expect(json['status'], 'pending');
      expect(json['relay_channel'], 'whatsapp');
      expect(json['dealer_message'], 'Test message');
      expect(json['estimated_amount'], 8.50);
      // Should not include id, created_at, updated_at
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
    });

    test('maps pickedUp status to picked_up', () {
      final relay = OrderRelay(
        id: 'r1',
        orderId: 'o1',
        riderId: 'rid1',
        dealerContactId: 'd1',
        status: OrderRelayStatus.pickedUp,
        createdAt: DateTime(2026, 2, 13),
        updatedAt: DateTime(2026, 2, 13),
      );

      expect(relay.toInsertJson()['status'], 'picked_up');
    });
  });
}
