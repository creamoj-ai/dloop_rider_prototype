import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/tokens.dart';
import '../../../../services/preferences_service.dart';

class VehicleSettingsSheet extends StatefulWidget {
  const VehicleSettingsSheet({super.key});

  @override
  State<VehicleSettingsSheet> createState() => _VehicleSettingsSheetState();
}

class _VehicleSettingsSheetState extends State<VehicleSettingsSheet> {
  int _vehicleIndex = 1; // 0=bici, 1=scooter, 2=auto
  double _maxDistance = 5.0;
  bool _loading = true;
  bool _saving = false;

  static const _vehicles = [
    ('bicicletta', 'Bicicletta', Icons.pedal_bike, 'Eco-friendly, ideale in centro'),
    ('scooter', 'Scooter', Icons.two_wheeler, 'Veloce, copre distanze medie'),
    ('auto', 'Auto', Icons.directions_car, 'Ordini grandi, distanze lunghe'),
  ];

  @override
  void initState() {
    super.initState();
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    try {
      final prefs = await PreferencesService.getPreferences();
      final vehicleType = prefs['vehicle_type'] as String? ?? 'scooter';
      final maxDist = (prefs['max_distance_km'] as num?)?.toDouble() ?? 5.0;

      setState(() {
        _vehicleIndex = _vehicles.indexWhere((v) => v.$1 == vehicleType);
        if (_vehicleIndex < 0) _vehicleIndex = 1;
        _maxDistance = maxDist.clamp(1.0, 15.0);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await PreferencesService.updateVehicle(
        vehicleType: _vehicles[_vehicleIndex].$1,
        maxDistanceKm: _maxDistance,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Salvato: ${_vehicles[_vehicleIndex].$2}, max ${_maxDistance.toStringAsFixed(1)} km'),
            backgroundColor: AppColors.bonusPurple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: AppColors.urgentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator(color: AppColors.bonusPurple)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bonusPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.settings, color: AppColors.bonusPurple, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Impostazioni Veicolo', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
                    Text('Salvate su Supabase', style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Vehicle type
          Text('Tipo di veicolo', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(3, (i) {
              final selected = i == _vehicleIndex;
              final vehicle = _vehicles[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _vehicleIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.bonusPurple.withValues(alpha: 0.15)
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: selected ? Border.all(color: AppColors.bonusPurple) : null,
                      ),
                      child: Column(
                        children: [
                          Icon(vehicle.$3, size: 28, color: selected ? AppColors.bonusPurple : cs.onSurfaceVariant),
                          const SizedBox(height: 6),
                          Text(
                            vehicle.$2,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? AppColors.bonusPurple : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            _vehicles[_vehicleIndex].$4,
            style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant),
          ),

          const SizedBox(height: 24),

          // Max distance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Distanza massima', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bonusPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_maxDistance.toStringAsFixed(1)} km', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.bonusPurple)),
              ),
            ],
          ),
          Slider(
            value: _maxDistance,
            min: 1,
            max: 15,
            divisions: 28,
            activeColor: AppColors.bonusPurple,
            onChanged: (v) => setState(() => _maxDistance = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 km', style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
              Text('15 km', style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),

          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 18),
              label: Text(_saving ? 'SALVATAGGIO...' : 'SALVA', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bonusPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
