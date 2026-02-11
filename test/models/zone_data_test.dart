import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/zone_data.dart';

void main() {
  final completeJson = {
    'id': 'zone-001',
    'name': 'Centro Storico',
    'demand': 'alta',
    'orders_per_hour': 12,
    'distance_km': 2.5,
    'earning_min': 8.0,
    'earning_max': 15.0,
    'latitude': 40.8518,
    'longitude': 14.2681,
    'updated_at': '2026-02-10T14:00:00Z',
  };

  group('ZoneDemand enum', () {
    test('has all expected values', () {
      expect(ZoneDemand.values, [
        ZoneDemand.alta,
        ZoneDemand.media,
        ZoneDemand.bassa,
      ]);
    });
  });

  group('ZoneData.fromJson', () {
    test('with complete data', () {
      final zone = ZoneData.fromJson(completeJson);

      expect(zone.id, 'zone-001');
      expect(zone.name, 'Centro Storico');
      expect(zone.demand, ZoneDemand.alta);
      expect(zone.ordersPerHour, 12);
      expect(zone.distanceKm, 2.5);
      expect(zone.earningMin, 8.0);
      expect(zone.earningMax, 15.0);
      expect(zone.latitude, 40.8518);
      expect(zone.longitude, 14.2681);
    });

    test('parses demand alta correctly', () {
      final json = Map<String, dynamic>.from(completeJson)..['demand'] = 'alta';
      expect(ZoneData.fromJson(json).demand, ZoneDemand.alta);
    });

    test('parses demand media correctly', () {
      final json = Map<String, dynamic>.from(completeJson)..['demand'] = 'media';
      expect(ZoneData.fromJson(json).demand, ZoneDemand.media);
    });

    test('parses demand bassa correctly', () {
      final json = Map<String, dynamic>.from(completeJson)..['demand'] = 'bassa';
      expect(ZoneData.fromJson(json).demand, ZoneDemand.bassa);
    });

    test('parses demand case-insensitive', () {
      final json = Map<String, dynamic>.from(completeJson)..['demand'] = 'ALTA';
      expect(ZoneData.fromJson(json).demand, ZoneDemand.alta);
    });

    test('unknown demand falls back to bassa', () {
      final json = Map<String, dynamic>.from(completeJson)
        ..['demand'] = 'unknown';
      expect(ZoneData.fromJson(json).demand, ZoneDemand.bassa);
    });

    test('with null lat/lng defaults to 0', () {
      final json = Map<String, dynamic>.from(completeJson)
        ..['latitude'] = null
        ..['longitude'] = null;
      final zone = ZoneData.fromJson(json);
      expect(zone.latitude, 0.0);
      expect(zone.longitude, 0.0);
    });
  });

  group('ZoneData computed properties', () {
    test('shortName with short name returns as-is', () {
      final zone = ZoneData.fromJson(
        Map<String, dynamic>.from(completeJson)..['name'] = 'Vomero',
      );
      expect(zone.shortName, 'Vomero');
    });

    test('shortName with multi-word returns last word', () {
      final zone = ZoneData.fromJson(completeJson);
      // 'Centro Storico' → 'Storico'
      expect(zone.shortName, 'Storico');
    });

    test('shortName with short prefix abbreviates', () {
      final zone = ZoneData.fromJson(
        Map<String, dynamic>.from(completeJson)..['name'] = 'Via Chiaia Test',
      );
      // 'Via' (3 chars) → 'V.Chiaia Test'
      expect(zone.shortName, 'V.Chiaia Test');
    });

    test('radiusMeters for alta demand', () {
      final zone = ZoneData.fromJson(
        Map<String, dynamic>.from(completeJson)..['demand'] = 'alta',
      );
      expect(zone.radiusMeters, 700);
    });

    test('radiusMeters for media demand', () {
      final zone = ZoneData.fromJson(
        Map<String, dynamic>.from(completeJson)..['demand'] = 'media',
      );
      expect(zone.radiusMeters, 550);
    });

    test('radiusMeters for bassa demand', () {
      final zone = ZoneData.fromJson(
        Map<String, dynamic>.from(completeJson)..['demand'] = 'bassa',
      );
      expect(zone.radiusMeters, 400);
    });

    test('demandLabel values', () {
      final alta = ZoneData.fromJson(
        Map<String, dynamic>.from(completeJson)..['demand'] = 'alta',
      );
      expect(alta.demandLabel, 'ALTA');

      final media = ZoneData.fromJson(
        Map<String, dynamic>.from(completeJson)..['demand'] = 'media',
      );
      expect(media.demandLabel, 'MEDIA');

      final bassa = ZoneData.fromJson(
        Map<String, dynamic>.from(completeJson)..['demand'] = 'bassa',
      );
      expect(bassa.demandLabel, 'BASSA');
    });

    test('demandColor is non-null for all demand levels', () {
      for (final demand in ['alta', 'media', 'bassa']) {
        final zone = ZoneData.fromJson(
          Map<String, dynamic>.from(completeJson)..['demand'] = demand,
        );
        expect(zone.demandColor, isNotNull);
      }
    });

    test('trending values', () {
      final alta = ZoneData.fromJson(
        Map<String, dynamic>.from(completeJson)..['demand'] = 'alta',
      );
      expect(alta.trending, 'up');

      final media = ZoneData.fromJson(
        Map<String, dynamic>.from(completeJson)..['demand'] = 'media',
      );
      expect(media.trending, 'flat');

      final bassa = ZoneData.fromJson(
        Map<String, dynamic>.from(completeJson)..['demand'] = 'bassa',
      );
      expect(bassa.trending, 'down');
    });

    test('trendText contains Italian description', () {
      final zone = ZoneData.fromJson(completeJson);
      expect(zone.trendText, contains('crescita'));
    });

    test('ordersHourLabel format', () {
      final zone = ZoneData.fromJson(completeJson);
      expect(zone.ordersHourLabel, '~12 ordini/h');
    });

    test('distanceLabel format', () {
      final zone = ZoneData.fromJson(completeJson);
      expect(zone.distanceLabel, '2.5 km');
    });

    test('earningLabel format', () {
      final zone = ZoneData.fromJson(completeJson);
      expect(zone.earningLabel, '€8-15/h stima');
    });

    test('ridersEstimate derived from ordersPerHour', () {
      final zone = ZoneData.fromJson(completeJson);
      // 12 * 0.6 = 7.2 → round = 7
      expect(zone.ridersEstimate, '7');
    });
  });
}
