import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/services/rush_hour_service.dart';

void main() {
  group('RushHourSlot', () {
    test('isActive during lunch (12:00-14:00) returns true', () {
      const slot = RushHourSlot(
        startHour: 12,
        endHour: 14,
        multiplier: 2.0,
        label: 'Pranzo',
      );

      expect(slot.isActive(DateTime(2026, 2, 10, 12, 0)), true);
      expect(slot.isActive(DateTime(2026, 2, 10, 12, 30)), true);
      expect(slot.isActive(DateTime(2026, 2, 10, 13, 59)), true);
    });

    test('isActive returns false outside range', () {
      const slot = RushHourSlot(
        startHour: 12,
        endHour: 14,
        multiplier: 2.0,
        label: 'Pranzo',
      );

      expect(slot.isActive(DateTime(2026, 2, 10, 11, 59)), false);
      expect(slot.isActive(DateTime(2026, 2, 10, 14, 0)), false);
      expect(slot.isActive(DateTime(2026, 2, 10, 8, 0)), false);
    });

    test('isActive during dinner (19:00-21:00) returns true', () {
      const slot = RushHourSlot(
        startHour: 19,
        endHour: 21,
        multiplier: 2.0,
        label: 'Cena',
      );

      expect(slot.isActive(DateTime(2026, 2, 10, 19, 0)), true);
      expect(slot.isActive(DateTime(2026, 2, 10, 20, 30)), true);
      expect(slot.isActive(DateTime(2026, 2, 10, 20, 59)), true);
    });

    test('isActive at exact end boundary returns false', () {
      const slot = RushHourSlot(
        startHour: 19,
        endHour: 21,
        multiplier: 2.0,
        label: 'Cena',
      );

      expect(slot.isActive(DateTime(2026, 2, 10, 21, 0)), false);
    });
  });

  group('RushHourService static config', () {
    test('has 2 rush hour slots', () {
      expect(RushHourService.rushHours.length, 2);
    });

    test('lunch slot is 12-14 with 2.0 multiplier', () {
      final lunch = RushHourService.rushHours[0];
      expect(lunch.startHour, 12);
      expect(lunch.endHour, 14);
      expect(lunch.multiplier, 2.0);
      expect(lunch.label, 'Pranzo');
    });

    test('dinner slot is 19-21 with 2.0 multiplier', () {
      final dinner = RushHourService.rushHours[1];
      expect(dinner.startHour, 19);
      expect(dinner.endHour, 21);
      expect(dinner.multiplier, 2.0);
      expect(dinner.label, 'Cena');
    });
  });

  group('RushHourService.formatTimeRemaining', () {
    test('with minutes < 60 returns "X min"', () {
      expect(RushHourService.formatTimeRemaining(30), '30 min');
      expect(RushHourService.formatTimeRemaining(1), '1 min');
      expect(RushHourService.formatTimeRemaining(59), '59 min');
    });

    test('with 0 minutes returns "0 min"', () {
      expect(RushHourService.formatTimeRemaining(0), '0 min');
    });

    test('with 60 minutes returns "1h 0m"', () {
      expect(RushHourService.formatTimeRemaining(60), '1h 0m');
    });

    test('with 90 minutes returns "1h 30m"', () {
      expect(RushHourService.formatTimeRemaining(90), '1h 30m');
    });

    test('with 150 minutes returns "2h 30m"', () {
      expect(RushHourService.formatTimeRemaining(150), '2h 30m');
    });

    test('with 120 minutes returns "2h 0m"', () {
      expect(RushHourService.formatTimeRemaining(120), '2h 0m');
    });
  });

  // Note: isRushHourNow(), getCurrentMultiplier(), getActiveSlot(),
  // minutesRemainingInRushHour(), minutesToNextRushHour()
  // all use DateTime.now() internally, so they're time-dependent.
  // We test them indirectly through RushHourSlot.isActive() which
  // accepts an explicit DateTime.
  //
  // For full testability, these methods would need a Clock injection.
  // Instead, we validate the logic by testing all slots with explicit times.

  group('RushHourService logic via slot testing', () {
    test('all rush hour slots are non-overlapping', () {
      final slots = RushHourService.rushHours;
      for (var i = 0; i < slots.length - 1; i++) {
        expect(slots[i].endHour, lessThanOrEqualTo(slots[i + 1].startHour),
            reason: 'Slot $i overlaps with slot ${i + 1}');
      }
    });

    test('no rush hour at 8:00 AM', () {
      final time = DateTime(2026, 2, 10, 8, 0);
      final isRush = RushHourService.rushHours.any((s) => s.isActive(time));
      expect(isRush, false);
    });

    test('rush hour at 12:30 PM', () {
      final time = DateTime(2026, 2, 10, 12, 30);
      final isRush = RushHourService.rushHours.any((s) => s.isActive(time));
      expect(isRush, true);
    });

    test('no rush hour at 15:00', () {
      final time = DateTime(2026, 2, 10, 15, 0);
      final isRush = RushHourService.rushHours.any((s) => s.isActive(time));
      expect(isRush, false);
    });

    test('rush hour at 19:45', () {
      final time = DateTime(2026, 2, 10, 19, 45);
      final isRush = RushHourService.rushHours.any((s) => s.isActive(time));
      expect(isRush, true);
    });

    test('no rush hour at 22:00', () {
      final time = DateTime(2026, 2, 10, 22, 0);
      final isRush = RushHourService.rushHours.any((s) => s.isActive(time));
      expect(isRush, false);
    });

    test('multiplier is 2.0 during rush, 1.0 otherwise', () {
      double getMultiplier(DateTime time) {
        for (final slot in RushHourService.rushHours) {
          if (slot.isActive(time)) return slot.multiplier;
        }
        return 1.0;
      }

      expect(getMultiplier(DateTime(2026, 2, 10, 10, 0)), 1.0);
      expect(getMultiplier(DateTime(2026, 2, 10, 12, 30)), 2.0);
      expect(getMultiplier(DateTime(2026, 2, 10, 16, 0)), 1.0);
      expect(getMultiplier(DateTime(2026, 2, 10, 20, 0)), 2.0);
      expect(getMultiplier(DateTime(2026, 2, 10, 23, 0)), 1.0);
    });
  });
}
