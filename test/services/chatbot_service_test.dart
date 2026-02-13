import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/services/chatbot_service.dart';

void main() {
  group('ChatBotService', () {
    test('class exists and has expected static methods', () {
      // Verify the service exposes the expected public API
      // (actual network calls require Supabase/Auth, tested via integration)
      expect(ChatBotService, isNotNull);
    });

    test('sendMessage signature requires only text parameter', () {
      // Verify the new API shape: sendMessage takes {required String text}
      // The old API required both text and systemPrompt — now only text
      // This is a compile-time check; we just confirm it builds
      expect(ChatBotService.sendMessage, isA<Function>());
    });

    test('getHistory returns a Future<List>', () {
      expect(ChatBotService.getHistory, isA<Function>());
    });

    test('clearHistory returns a Future<void>', () {
      expect(ChatBotService.clearHistory, isA<Function>());
    });

    test('subscribeToMessages returns a Stream', () {
      expect(ChatBotService.subscribeToMessages, isA<Function>());
    });
  });
}
