import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the Smart Dispatch scoring algorithm.
/// This is a Dart mirror of the TypeScript scoreRider() in dispatch-order/index.ts.

// Score weights (from roadmap-vision-2026.md Section 3)
const wProximity = 0.40;
const wRating = 0.30;
const wAcceptance = 0.15;
const wSpecialization = 0.10;
const wAvailability = 0.05;

/// Pure function mirror of dispatch-order scoreRider()
Map<String, dynamic> scoreRider({
  required double distanceKm,
  required double maxDistance,
  required double avgRating,
  required double acceptanceRate,
  required bool hasDeliveredFromDealer,
}) {
  final proximity = maxDistance > 0
      ? max(0.0, 1 - (distanceKm / maxDistance))
      : 1.0;
  final rating = min((avgRating) / 5.0, 1.0);
  final acceptance = min(acceptanceRate, 1.0);
  final specialization = hasDeliveredFromDealer ? 1.0 : 0.0;
  const availability = 1.0;

  final totalScore = wProximity * proximity +
      wRating * rating +
      wAcceptance * acceptance +
      wSpecialization * specialization +
      wAvailability * availability;

  return {
    'total_score': (totalScore * 1000).round() / 1000,
    'proximity': (proximity * 100).round() / 100,
    'rating': (rating * 100).round() / 100,
    'acceptance': (acceptance * 100).round() / 100,
    'specialization': specialization,
    'availability': availability,
  };
}

void main() {
  group('Dispatch scoring algorithm', () {
    test('weights sum to 1.0', () {
      expect(wProximity + wRating + wAcceptance + wSpecialization + wAvailability, 1.0);
    });

    test('perfect score for closest rider with all factors at max', () {
      final result = scoreRider(
        distanceKm: 0.0,
        maxDistance: 5.0,
        avgRating: 5.0,
        acceptanceRate: 1.0,
        hasDeliveredFromDealer: true,
      );

      expect(result['total_score'], 1.0);
      expect(result['proximity'], 1.0);
      expect(result['rating'], 1.0);
      expect(result['acceptance'], 1.0);
      expect(result['specialization'], 1.0);
      expect(result['availability'], 1.0);
    });

    test('proximity is 0 for farthest rider', () {
      final result = scoreRider(
        distanceKm: 5.0,
        maxDistance: 5.0,
        avgRating: 5.0,
        acceptanceRate: 1.0,
        hasDeliveredFromDealer: false,
      );

      expect(result['proximity'], 0.0);
      // Score = 0*0.4 + 1*0.3 + 1*0.15 + 0*0.1 + 1*0.05 = 0.50
      expect(result['total_score'], 0.5);
    });

    test('proximity dominates ranking for nearby riders', () {
      final closeRider = scoreRider(
        distanceKm: 0.5,
        maxDistance: 5.0,
        avgRating: 4.0,
        acceptanceRate: 0.8,
        hasDeliveredFromDealer: false,
      );

      final farRider = scoreRider(
        distanceKm: 4.5,
        maxDistance: 5.0,
        avgRating: 5.0,
        acceptanceRate: 1.0,
        hasDeliveredFromDealer: false,
      );

      expect(closeRider['total_score'], greaterThan(farRider['total_score']));
    });

    test('specialization bonus adds 0.10 to score', () {
      final withSpecialization = scoreRider(
        distanceKm: 2.0,
        maxDistance: 5.0,
        avgRating: 4.0,
        acceptanceRate: 0.9,
        hasDeliveredFromDealer: true,
      );

      final withoutSpecialization = scoreRider(
        distanceKm: 2.0,
        maxDistance: 5.0,
        avgRating: 4.0,
        acceptanceRate: 0.9,
        hasDeliveredFromDealer: false,
      );

      final diff = withSpecialization['total_score'] - withoutSpecialization['total_score'];
      expect(diff, closeTo(0.10, 0.01)); // specialization weight
    });

    test('rating 3.0/5.0 yields 0.60 factor', () {
      final result = scoreRider(
        distanceKm: 0.0,
        maxDistance: 5.0,
        avgRating: 3.0,
        acceptanceRate: 1.0,
        hasDeliveredFromDealer: false,
      );

      expect(result['rating'], 0.60);
    });

    test('acceptance rate below 1.0 reduces score', () {
      final highAcceptance = scoreRider(
        distanceKm: 1.0,
        maxDistance: 5.0,
        avgRating: 4.5,
        acceptanceRate: 1.0,
        hasDeliveredFromDealer: false,
      );

      final lowAcceptance = scoreRider(
        distanceKm: 1.0,
        maxDistance: 5.0,
        avgRating: 4.5,
        acceptanceRate: 0.5,
        hasDeliveredFromDealer: false,
      );

      expect(highAcceptance['total_score'], greaterThan(lowAcceptance['total_score']));
    });

    test('maxDistance 0 gives proximity 1.0', () {
      final result = scoreRider(
        distanceKm: 0.0,
        maxDistance: 0.0,
        avgRating: 5.0,
        acceptanceRate: 1.0,
        hasDeliveredFromDealer: false,
      );

      expect(result['proximity'], 1.0);
    });

    test('realistic scenario: 3 riders ranked correctly', () {
      // Rider A: closest, good rating, specialist
      final riderA = scoreRider(
        distanceKm: 0.5,
        maxDistance: 4.0,
        avgRating: 4.5,
        acceptanceRate: 0.95,
        hasDeliveredFromDealer: true,
      );

      // Rider B: medium distance, perfect stats, not specialist
      final riderB = scoreRider(
        distanceKm: 2.0,
        maxDistance: 4.0,
        avgRating: 5.0,
        acceptanceRate: 1.0,
        hasDeliveredFromDealer: false,
      );

      // Rider C: far, low rating, low acceptance
      final riderC = scoreRider(
        distanceKm: 3.5,
        maxDistance: 4.0,
        avgRating: 3.5,
        acceptanceRate: 0.6,
        hasDeliveredFromDealer: false,
      );

      expect(riderA['total_score'], greaterThan(riderB['total_score']));
      expect(riderB['total_score'], greaterThan(riderC['total_score']));
    });
  });
}
