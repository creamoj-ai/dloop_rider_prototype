import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/chat_message.dart';

void main() {
  group('SenderType enum', () {
    test('has all expected values', () {
      expect(SenderType.values, [
        SenderType.rider,
        SenderType.support,
        SenderType.system,
      ]);
    });
  });

  group('ChatMessage.fromJson', () {
    test('with complete data', () {
      final json = {
        'id': 'chat-001',
        'conversation_id': 'conv-abc',
        'sender_type': 'rider',
        'sender_id': 'rider-123',
        'body': 'Ho un problema con la consegna',
        'is_read': false,
        'created_at': '2026-02-10T14:00:00Z',
      };

      final msg = ChatMessage.fromJson(json);

      expect(msg.id, 'chat-001');
      expect(msg.conversationId, 'conv-abc');
      expect(msg.senderType, SenderType.rider);
      expect(msg.senderId, 'rider-123');
      expect(msg.body, 'Ho un problema con la consegna');
      expect(msg.isRead, false);
      expect(msg.createdAt.year, 2026);
    });

    test('with missing fields uses defaults', () {
      final json = <String, dynamic>{
        'id': null,
        'conversation_id': null,
      };

      final msg = ChatMessage.fromJson(json);

      expect(msg.id, '');
      expect(msg.conversationId, '');
      expect(msg.senderType, SenderType.system);
      expect(msg.senderId, isNull);
      expect(msg.body, '');
      expect(msg.isRead, false);
    });

    test('maps sender_type string to enum', () {
      final riderJson = {
        'id': '1',
        'conversation_id': 'c1',
        'sender_type': 'rider',
        'body': 'test',
        'created_at': '2026-02-10T12:00:00Z',
      };
      expect(ChatMessage.fromJson(riderJson).senderType, SenderType.rider);

      final supportJson = {
        'id': '2',
        'conversation_id': 'c1',
        'sender_type': 'support',
        'body': 'test',
        'created_at': '2026-02-10T12:00:00Z',
      };
      expect(ChatMessage.fromJson(supportJson).senderType, SenderType.support);

      final systemJson = {
        'id': '3',
        'conversation_id': 'c1',
        'sender_type': 'system',
        'body': 'test',
        'created_at': '2026-02-10T12:00:00Z',
      };
      expect(ChatMessage.fromJson(systemJson).senderType, SenderType.system);
    });

    test('unknown sender_type falls back to system', () {
      final json = {
        'id': '4',
        'conversation_id': 'c1',
        'sender_type': 'unknown',
        'body': 'test',
        'created_at': '2026-02-10T12:00:00Z',
      };

      expect(ChatMessage.fromJson(json).senderType, SenderType.system);
    });
  });

  group('ChatMessage computed properties', () {
    test('isFromRider', () {
      final msg = ChatMessage(
        id: '1',
        conversationId: 'c1',
        senderType: SenderType.rider,
        body: 'test',
        createdAt: DateTime(2026, 2, 10),
      );
      expect(msg.isFromRider, true);
      expect(msg.isFromSupport, false);
      expect(msg.isSystemMessage, false);
    });

    test('isFromSupport', () {
      final msg = ChatMessage(
        id: '2',
        conversationId: 'c1',
        senderType: SenderType.support,
        body: 'test',
        createdAt: DateTime(2026, 2, 10),
      );
      expect(msg.isFromSupport, true);
      expect(msg.isFromRider, false);
      expect(msg.isSystemMessage, false);
    });

    test('isSystemMessage', () {
      final msg = ChatMessage(
        id: '3',
        conversationId: 'c1',
        senderType: SenderType.system,
        body: 'test',
        createdAt: DateTime(2026, 2, 10),
      );
      expect(msg.isSystemMessage, true);
      expect(msg.isFromRider, false);
      expect(msg.isFromSupport, false);
    });
  });

  group('ChatMessage.toJson', () {
    test('serializes correctly', () {
      final msg = ChatMessage(
        id: 'tj-1',
        conversationId: 'conv-1',
        senderType: SenderType.rider,
        senderId: 'rider-123',
        body: 'Messaggio di test',
        createdAt: DateTime(2026, 2, 10),
      );

      final json = msg.toJson();

      expect(json['conversation_id'], 'conv-1');
      expect(json['sender_type'], 'rider');
      expect(json['sender_id'], 'rider-123');
      expect(json['body'], 'Messaggio di test');
      // toJson excludes id and created_at
      expect(json.containsKey('id'), false);
      expect(json.containsKey('created_at'), false);
    });
  });

  group('SupportConversation', () {
    group('fromJson', () {
      test('with complete data', () {
        final json = {
          'id': 'conv-001',
          'rider_id': 'rider-abc',
          'subject': 'Problema consegna',
          'status': 'open',
          'created_at': '2026-02-10T10:00:00Z',
          'updated_at': '2026-02-10T14:00:00Z',
        };

        final conv = SupportConversation.fromJson(json);

        expect(conv.id, 'conv-001');
        expect(conv.riderId, 'rider-abc');
        expect(conv.subject, 'Problema consegna');
        expect(conv.status, 'open');
        expect(conv.isOpen, true);
      });

      test('with missing fields uses defaults', () {
        final json = <String, dynamic>{
          'id': null,
          'rider_id': null,
        };

        final conv = SupportConversation.fromJson(json);

        expect(conv.id, '');
        expect(conv.riderId, '');
        expect(conv.subject, 'Supporto');
        expect(conv.status, 'open');
      });
    });

    test('isOpen returns false for closed status', () {
      final conv = SupportConversation(
        id: '1',
        riderId: 'r1',
        status: 'closed',
        createdAt: DateTime(2026, 2, 10),
        updatedAt: DateTime(2026, 2, 10),
      );
      expect(conv.isOpen, false);
    });

    test('toJson serializes correctly', () {
      final conv = SupportConversation(
        id: 'conv-1',
        riderId: 'rider-1',
        subject: 'Test subject',
        status: 'open',
        createdAt: DateTime(2026, 2, 10),
        updatedAt: DateTime(2026, 2, 10),
      );

      final json = conv.toJson();
      expect(json['rider_id'], 'rider-1');
      expect(json['subject'], 'Test subject');
      expect(json['status'], 'open');
    });
  });
}
