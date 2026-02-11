import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/services/chatbot_service.dart';

void main() {
  group('ChatBotService.buildSystemPrompt', () {
    test('contains rider name', () {
      final prompt = ChatBotService.buildSystemPrompt(
        riderName: 'Mario',
      );

      expect(prompt, contains('Mario'));
    });

    test('contains formatted earnings data', () {
      final prompt = ChatBotService.buildSystemPrompt(
        riderName: 'Luigi',
        todayEarnings: 45.80,
        todayOrders: 6,
      );

      expect(prompt, contains('45.80'));
      expect(prompt, contains('6 ordini'));
    });

    test('contains streak, rating, and level', () {
      final prompt = ChatBotService.buildSystemPrompt(
        riderName: 'Anna',
        streak: 12,
        rating: 4.9,
        level: 7,
      );

      expect(prompt, contains('streak 12'));
      expect(prompt, contains('4.9'));
      expect(prompt, contains('livello 7'));
    });

    test('contains lifetime stats', () {
      final prompt = ChatBotService.buildSystemPrompt(
        riderName: 'Marco',
        lifetimeEarnings: 5230.0,
        lifetimeOrders: 620,
      );

      expect(prompt, contains('5230'));
      expect(prompt, contains('620 ordini'));
    });

    test('is in Italian', () {
      final prompt = ChatBotService.buildSystemPrompt(
        riderName: 'Test',
      );

      expect(prompt, contains('italiano'));
      expect(prompt, contains('dloop'));
      expect(prompt, contains('rider'));
    });

    test('with zero/default values', () {
      final prompt = ChatBotService.buildSystemPrompt(
        riderName: 'Newbie',
        todayEarnings: 0,
        todayOrders: 0,
        streak: 0,
        rating: 0,
        level: 1,
        lifetimeEarnings: 0,
        lifetimeOrders: 0,
      );

      expect(prompt, contains('Newbie'));
      expect(prompt, contains('0.00'));
      expect(prompt, contains('0 ordini'));
      expect(prompt, contains('livello 1'));
    });

    test('contains help topics', () {
      final prompt = ChatBotService.buildSystemPrompt(
        riderName: 'Test',
      );

      expect(prompt, contains('guadagnare'));
      expect(prompt, contains('livelli'));
      expect(prompt, contains('FAQ'));
      expect(prompt, contains('hold'));
      expect(prompt, contains('rating'));
      expect(prompt, contains('supporto'));
    });
  });
}
