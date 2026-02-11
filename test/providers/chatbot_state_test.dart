import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/bot_message.dart';
import 'package:dloop_rider_prototype/providers/chatbot_provider.dart';

void main() {
  group('ChatBotState', () {
    test('initial state: isLoading=true, messages=[], isTyping=false', () {
      const state = ChatBotState();

      expect(state.messages, isEmpty);
      expect(state.isLoading, true);
      expect(state.isTyping, false);
      expect(state.errorMessage, isNull);
    });

    test('copyWith overwrites specified fields', () {
      const state = ChatBotState();

      final messages = [
        BotMessage(
          id: '1',
          riderId: 'r1',
          role: 'user',
          content: 'Ciao',
          createdAt: DateTime(2026, 2, 10),
        ),
      ];

      final updated = state.copyWith(
        messages: messages,
        isLoading: false,
        isTyping: true,
        errorMessage: 'Test error',
      );

      expect(updated.messages.length, 1);
      expect(updated.isLoading, false);
      expect(updated.isTyping, true);
      expect(updated.errorMessage, 'Test error');
    });

    test('copyWith without errorMessage resets it to null', () {
      final state = const ChatBotState().copyWith(
        errorMessage: 'Some error',
      );
      expect(state.errorMessage, 'Some error');

      // copyWith uses errorMessage parameter directly (not ?? fallback)
      // so passing null or not passing it clears the error
      final cleared = state.copyWith();
      expect(cleared.errorMessage, isNull);
    });

    test('copyWith preserves messages when not specified', () {
      final messages = [
        BotMessage(
          id: '1',
          riderId: 'r1',
          role: 'assistant',
          content: 'Risposta',
          createdAt: DateTime(2026, 2, 10),
        ),
        BotMessage(
          id: '2',
          riderId: 'r1',
          role: 'user',
          content: 'Domanda',
          createdAt: DateTime(2026, 2, 10),
        ),
      ];

      final state = ChatBotState(messages: messages);
      final updated = state.copyWith(isTyping: true);

      expect(updated.messages.length, 2);
      expect(updated.isTyping, true);
    });
  });
}
