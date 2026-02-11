import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/services/preferences_service.dart';

void main() {
  group('RiderSettings', () {
    group('defaults()', () {
      test('returns correct default values', () {
        final settings = RiderSettings.defaults();

        expect(settings.pushNotifications, true);
        expect(settings.orderSounds, true);
        expect(settings.biometricLock, true);
        expect(settings.distanceUnit, 'km');
      });
    });

    group('fromJson', () {
      test('with complete data', () {
        final json = {
          'push_notifications': false,
          'order_sounds': false,
          'biometric_lock': false,
          'distance_unit': 'mi',
        };

        final settings = RiderSettings.fromJson(json);

        expect(settings.pushNotifications, false);
        expect(settings.orderSounds, false);
        expect(settings.biometricLock, false);
        expect(settings.distanceUnit, 'mi');
      });

      test('with missing fields uses defaults', () {
        final settings = RiderSettings.fromJson({});

        expect(settings.pushNotifications, true);
        expect(settings.orderSounds, true);
        expect(settings.biometricLock, true);
        expect(settings.distanceUnit, 'km');
      });

      test('with null values uses defaults', () {
        final json = {
          'push_notifications': null,
          'order_sounds': null,
          'biometric_lock': null,
          'distance_unit': null,
        };

        final settings = RiderSettings.fromJson(json);

        expect(settings.pushNotifications, true);
        expect(settings.orderSounds, true);
        expect(settings.biometricLock, true);
        expect(settings.distanceUnit, 'km');
      });

      test('with mixed true/false values', () {
        final json = {
          'push_notifications': true,
          'order_sounds': false,
          'biometric_lock': true,
          'distance_unit': 'km',
        };

        final settings = RiderSettings.fromJson(json);

        expect(settings.pushNotifications, true);
        expect(settings.orderSounds, false);
        expect(settings.biometricLock, true);
        expect(settings.distanceUnit, 'km');
      });
    });
  });
}
