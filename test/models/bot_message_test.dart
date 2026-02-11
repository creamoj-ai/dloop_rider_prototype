import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/bot_message.dart';

void main() {
  group('BotMessage.fromJson', () {
    test('with complete data', () {
      final json = {
        'id': 'msg-001',
        'rider_id': 'rider-abc',
        'role': 'assistant',
        'content': 'Ciao! Come posso aiutarti?',
        'tokens_used': 42,
        'model': 'gpt-4o-mini',
        'created_at': '2026-02-10T14:00:00Z',
      };

      final msg = BotMessage.fromJson(json);

      expect(msg.id, 'msg-001');
      expect(msg.riderId, 'rider-abc');
      expect(msg.role, 'assistant');
      expect(msg.content, 'Ciao! Come posso aiutarti?');
      expect(msg.tokensUsed, 42);
      expect(msg.model, 'gpt-4o-mini');
      expect(msg.createdAt.year, 2026);
    });

    test('with missing fields uses defaults', () {
      final json = <String, dynamic>{
        'id': null,
        'rider_id': null,
      };

      final msg = BotMessage.fromJson(json);

      expect(msg.id, '');
      expect(msg.riderId, '');
      expect(msg.role, 'user');
      expect(msg.content, '');
      expect(msg.tokensUsed, 0);
      expect(msg.model, 'gpt-4o-mini');
    });

    test('with tokens_used as string', () {
      final json = {
        'id': 'msg-002',
        'rider_id': 'r1',
        'role': 'assistant',
        'content': 'Test',
        'tokens_used': '128',
        'model': 'gpt-4o-mini',
        'created_at': '2026-02-10T14:00:00Z',
      };

      expect(BotMessage.fromJson(json).tokensUsed, 128);
    });
  });

  group('BotMessage computed properties', () {
    test('isUser returns true for role=user', () {
      final msg = BotMessage(
        id: '1',
        riderId: 'r1',
        role: 'user',
        content: 'Hello',
        createdAt: DateTime(2026, 2, 10),
      );

      expect(msg.isUser, true);
      expect(msg.isAssistant, false);
    });

    test('isAssistant returns true for role=assistant', () {
      final msg = BotMessage(
        id: '2',
        riderId: 'r1',
        role: 'assistant',
        content: 'Ciao!',
        createdAt: DateTime(2026, 2, 10),
      );

      expect(msg.isAssistant, true);
      expect(msg.isUser, false);
    });

    test('isUser and isAssistant both false for system role', () {
      final msg = BotMessage(
        id: '3',
        riderId: 'r1',
        role: 'system',
        content: 'System prompt',
        createdAt: DateTime(2026, 2, 10),
      );

      expect(msg.isUser, false);
      expect(msg.isAssistant, false);
    });
  });

  group('BotMessage.toOpenAiMessage', () {
    test('returns correct map for API', () {
      final msg = BotMessage(
        id: '4',
        riderId: 'r1',
        role: 'user',
        content: 'Quanto ho guadagnato oggi?',
        createdAt: DateTime(2026, 2, 10),
      );

      final apiMsg = msg.toOpenAiMessage();

      expect(apiMsg, {'role': 'user', 'content': 'Quanto ho guadagnato oggi?'});
      expect(apiMsg.length, 2);
    });

    test('returns correct map for assistant role', () {
      final msg = BotMessage(
        id: '5',
        riderId: 'r1',
        role: 'assistant',
        content: 'Hai guadagnato 45 euro oggi!',
        createdAt: DateTime(2026, 2, 10),
      );

      final apiMsg = msg.toOpenAiMessage();

      expect(apiMsg['role'], 'assistant');
      expect(apiMsg['content'], 'Hai guadagnato 45 euro oggi!');
    });
  });
}
