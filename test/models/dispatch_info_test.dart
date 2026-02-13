import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/dispatch_info.dart';

void main() {
  group('DispatchInfo.fromJson', () {
    test('parses complete JSON correctly', () {
      final json = {
        'score': 0.875,
        'factors_json': {
          'proximity': 0.95,
          'rating': 0.80,
          'acceptance': 1.0,
          'specialization': 0.0,
          'availability': 1.0,
        },
        'distance_km': 1.2,
        'attempt_number': 2,
        'created_at': '2026-02-13T12:00:00Z',
      };

      final info = DispatchInfo.fromJson(json);

      expect(info.score, 0.875);
      expect(info.factors['proximity'], 0.95);
      expect(info.factors['rating'], 0.80);
      expect(info.factors['acceptance'], 1.0);
      expect(info.factors['specialization'], 0.0);
      expect(info.factors['availability'], 1.0);
      expect(info.distanceKm, 1.2);
      expect(info.attemptNumber, 2);
      expect(info.createdAt.year, 2026);
    });

    test('handles missing/null fields with defaults', () {
      final json = <String, dynamic>{};

      final info = DispatchInfo.fromJson(json);

      expect(info.score, 0.0);
      expect(info.factors, isEmpty);
      expect(info.distanceKm, 0.0);
      expect(info.attemptNumber, 1);
    });

    test('handles numeric types (int as score)', () {
      final json = {
        'score': 1,
        'factors_json': {'proximity': 1},
        'distance_km': 3,
        'attempt_number': 1,
        'created_at': '2026-02-13T10:00:00Z',
      };

      final info = DispatchInfo.fromJson(json);

      expect(info.score, 1.0);
      expect(info.factors['proximity'], 1.0);
      expect(info.distanceKm, 3.0);
    });
  });

  group('DispatchInfo computed properties', () {
    test('scoreLabel formats as percentage', () {
      final info = DispatchInfo(
        score: 0.875,
        factors: const {},
        distanceKm: 1.0,
        attemptNumber: 1,
        createdAt: DateTime(2026, 2, 13),
      );

      expect(info.scoreLabel, '88%');
    });

    test('scoreLabel with perfect score', () {
      final info = DispatchInfo(
        score: 1.0,
        factors: const {},
        distanceKm: 0,
        attemptNumber: 1,
        createdAt: DateTime(2026, 2, 13),
      );

      expect(info.scoreLabel, '100%');
    });

    test('distanceLabel formats with 1 decimal', () {
      final info = DispatchInfo(
        score: 0.5,
        factors: const {},
        distanceKm: 2.567,
        attemptNumber: 1,
        createdAt: DateTime(2026, 2, 13),
      );

      expect(info.distanceLabel, '2.6 km');
    });
  });
}
