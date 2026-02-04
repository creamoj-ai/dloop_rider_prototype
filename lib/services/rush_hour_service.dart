/// Rush Hour Service
/// Gestisce la rilevazione delle fasce orarie di punta per applicare
/// il moltiplicatore premium ai guadagni.

class RushHourSlot {
  final int startHour;
  final int endHour;
  final double multiplier;
  final String label;

  const RushHourSlot({
    required this.startHour,
    required this.endHour,
    required this.multiplier,
    required this.label,
  });

  bool isActive(DateTime time) {
    return time.hour >= startHour && time.hour < endHour;
  }
}

class RushHourService {
  // Fasce orarie rush hour configurabili
  static const List<RushHourSlot> rushHours = [
    RushHourSlot(
      startHour: 12,
      endHour: 14,
      multiplier: 2.0,
      label: 'Pranzo',
    ),
    RushHourSlot(
      startHour: 19,
      endHour: 21,
      multiplier: 2.0,
      label: 'Cena',
    ),
  ];

  /// Controlla se è rush hour adesso
  static bool isRushHourNow() {
    final now = DateTime.now();
    return rushHours.any((slot) => slot.isActive(now));
  }

  /// Ritorna il moltiplicatore corrente (1.0 normale, 2.0 rush)
  static double getCurrentMultiplier() {
    final now = DateTime.now();
    for (var slot in rushHours) {
      if (slot.isActive(now)) {
        return slot.multiplier;
      }
    }
    return 1.0;
  }

  /// Ritorna lo slot rush hour attivo (o null)
  static RushHourSlot? getActiveSlot() {
    final now = DateTime.now();
    for (var slot in rushHours) {
      if (slot.isActive(now)) {
        return slot;
      }
    }
    return null;
  }

  /// Minuti rimanenti alla fine del rush hour corrente
  static int? minutesRemainingInRushHour() {
    final now = DateTime.now();
    final activeSlot = getActiveSlot();
    if (activeSlot == null) return null;

    final endTime = DateTime(now.year, now.month, now.day, activeSlot.endHour);
    return endTime.difference(now).inMinutes;
  }

  /// Minuti alla prossima rush hour (null se già in rush hour)
  static int? minutesToNextRushHour() {
    final now = DateTime.now();

    // Se siamo già in rush hour, ritorna null
    if (isRushHourNow()) return null;

    // Cerca la prossima rush hour oggi
    for (var slot in rushHours) {
      if (now.hour < slot.startHour) {
        final nextRush = DateTime(now.year, now.month, now.day, slot.startHour);
        return nextRush.difference(now).inMinutes;
      }
    }

    // Se tutte le rush hour di oggi sono passate, calcola per domani
    final tomorrowFirstRush = DateTime(
      now.year,
      now.month,
      now.day + 1,
      rushHours.first.startHour,
    );
    return tomorrowFirstRush.difference(now).inMinutes;
  }

  /// Formatta il tempo rimanente in modo leggibile
  static String formatTimeRemaining(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}
