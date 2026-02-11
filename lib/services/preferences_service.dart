import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/retry.dart';

class PreferencesService {
  static final _client = Supabase.instance.client;
  static String? get _userId => _client.auth.currentUser?.id;

  /// Fetch rider preferences (creates default if not found)
  static Future<Map<String, dynamic>> getPreferences() async {
    if (_userId == null) return _defaults;

    return retry(() async {
      final res = await _client
          .from('rider_preferences')
          .select()
          .eq('rider_id', _userId!)
          .maybeSingle();

      if (res != null) return res;

      // Create default preferences if not found
      final inserted = await _client
          .from('rider_preferences')
          .insert({
            'rider_id': _userId!,
            'vehicle_type': 'scooter',
            'max_distance_km': 5.0,
            'checklist': [],
          })
          .select()
          .single();

      return inserted;
    });
  }

  /// Update vehicle settings
  static Future<void> updateVehicle({
    required String vehicleType,
    required double maxDistanceKm,
  }) async {
    if (_userId == null) return;

    await retry(() async {
      await _client
          .from('rider_preferences')
          .upsert({
            'rider_id': _userId!,
            'vehicle_type': vehicleType,
            'max_distance_km': maxDistanceKm,
          }, onConflict: 'rider_id');
    });
  }

  /// Update checklist
  static Future<void> updateChecklist(List<String> checkedItems) async {
    if (_userId == null) return;

    await retry(() async {
      await _client
          .from('rider_preferences')
          .upsert({
            'rider_id': _userId!,
            'checklist': checkedItems,
          }, onConflict: 'rider_id');
    });
  }

  /// Fetch settings (push_notifications, order_sounds, biometric_lock, distance_unit)
  static Future<RiderSettings> getSettings() async {
    if (_userId == null) return RiderSettings.defaults();

    return retry(() async {
      final res = await _client
          .from('rider_preferences')
          .select('push_notifications, order_sounds, biometric_lock, distance_unit')
          .eq('rider_id', _userId!)
          .maybeSingle();

      if (res != null) return RiderSettings.fromJson(res);
      return RiderSettings.defaults();
    });
  }

  /// Update a single setting by key
  static Future<void> updateSetting(String key, dynamic value) async {
    if (_userId == null) return;

    await retry(() async {
      await _client
          .from('rider_preferences')
          .upsert({
            'rider_id': _userId!,
            key: value,
          }, onConflict: 'rider_id');
    });
  }

  static Map<String, dynamic> get _defaults => {
    'vehicle_type': 'scooter',
    'max_distance_km': 5.0,
    'checklist': <dynamic>[],
  };
}

class RiderSettings {
  final bool pushNotifications;
  final bool orderSounds;
  final bool biometricLock;
  final String distanceUnit;

  RiderSettings({
    required this.pushNotifications,
    required this.orderSounds,
    required this.biometricLock,
    required this.distanceUnit,
  });

  factory RiderSettings.defaults() => RiderSettings(
    pushNotifications: true,
    orderSounds: true,
    biometricLock: true,
    distanceUnit: 'km',
  );

  factory RiderSettings.fromJson(Map<String, dynamic> json) => RiderSettings(
    pushNotifications: json['push_notifications'] as bool? ?? true,
    orderSounds: json['order_sounds'] as bool? ?? true,
    biometricLock: json['biometric_lock'] as bool? ?? true,
    distanceUnit: json['distance_unit'] as String? ?? 'km',
  );
}
