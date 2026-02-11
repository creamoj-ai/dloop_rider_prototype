import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/rider.dart';
import '../../services/pricing_service.dart';
import '../../theme/tokens.dart';

/// Provider per le impostazioni tariffe del rider
final riderPricingProvider = StateNotifierProvider<RiderPricingNotifier, RiderPricing>(
  (ref) => RiderPricingNotifier(),
);

class RiderPricingNotifier extends StateNotifier<RiderPricing> {
  RiderPricingNotifier() : super(const RiderPricing()) {
    _loadFromSupabase();
  }

  Timer? _saveTimer;

  Future<void> _loadFromSupabase() async {
    try {
      final pricing = await PricingService.getRiderPricing();
      state = pricing;
    } catch (_) {
      // Keep defaults
    }
  }

  void _debouncedSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      PricingService.saveRiderPricing(state);
    });
  }

  void flushSave() {
    _saveTimer?.cancel();
    PricingService.saveRiderPricing(state);
  }

  void updateRatePerKm(double value) {
    state = state.copyWith(ratePerKm: value);
    _debouncedSave();
  }

  void updateMinDeliveryFee(double value) {
    state = state.copyWith(minDeliveryFee: value);
    _debouncedSave();
  }

  void updateHoldCostPerMin(double value) {
    state = state.copyWith(holdCostPerMin: value);
    _debouncedSave();
  }

  void updateHoldFreeMinutes(int value) {
    state = state.copyWith(holdFreeMinutes: value);
    _debouncedSave();
  }

  void updateShortDistanceMax(double value) {
    state = state.copyWith(shortDistanceMax: value);
    _debouncedSave();
  }

  void updateMediumDistanceMax(double value) {
    state = state.copyWith(mediumDistanceMax: value);
    _debouncedSave();
  }

  void updateLongDistanceBonus(double value) {
    state = state.copyWith(longDistanceBonus: value);
    _debouncedSave();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

class PricingSettingsScreen extends ConsumerStatefulWidget {
  const PricingSettingsScreen({super.key});

  @override
  ConsumerState<PricingSettingsScreen> createState() => _PricingSettingsScreenState();
}

class _PricingSettingsScreenState extends ConsumerState<PricingSettingsScreen> {
  @override
  void dispose() {
    try {
      ref.read(riderPricingProvider.notifier).flushSave();
    } catch (_) {
      // Provider may already be disposed
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pricing = ref.watch(riderPricingProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Text(
          'Le Mie Tariffe',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earnings preview
            _EarningsPreview(pricing: pricing),
            const SizedBox(height: 24),

            // Base rate section
            _SectionHeader(title: 'Tariffa Base', icon: Icons.euro),
            const SizedBox(height: 12),
            _PricingSlider(
              label: 'Tariffa per km',
              value: pricing.ratePerKm,
              min: 0.50,
              max: 3.00,
              unit: '€/km',
              onChanged: (v) => ref.read(riderPricingProvider.notifier).updateRatePerKm(v),
            ),
            const SizedBox(height: 8),
            _PricingSlider(
              label: 'Minimo garantito',
              value: pricing.minDeliveryFee,
              min: 1.00,
              max: 8.00,
              unit: '€',
              onChanged: (v) => ref.read(riderPricingProvider.notifier).updateMinDeliveryFee(v),
            ),

            const SizedBox(height: 28),

            // Hold cost section
            _SectionHeader(title: 'Costo Attesa', icon: Icons.hourglass_bottom),
            const SizedBox(height: 12),
            _PricingSlider(
              label: 'Costo per minuto (dopo soglia)',
              value: pricing.holdCostPerMin,
              min: 0.05,
              max: 0.50,
              unit: '€/min',
              onChanged: (v) => ref.read(riderPricingProvider.notifier).updateHoldCostPerMin(v),
            ),
            const SizedBox(height: 8),
            _PricingIntSlider(
              label: 'Minuti gratuiti',
              value: pricing.holdFreeMinutes,
              min: 0,
              max: 15,
              unit: 'min',
              onChanged: (v) => ref.read(riderPricingProvider.notifier).updateHoldFreeMinutes(v),
            ),

            const SizedBox(height: 28),

            // Distance tiers section
            _SectionHeader(title: 'Fasce Distanza', icon: Icons.route),
            const SizedBox(height: 12),
            _PricingSlider(
              label: 'Soglia corta (min garantito)',
              value: pricing.shortDistanceMax,
              min: 1.0,
              max: 4.0,
              unit: 'km',
              onChanged: (v) => ref.read(riderPricingProvider.notifier).updateShortDistanceMax(v),
            ),
            const SizedBox(height: 8),
            _PricingSlider(
              label: 'Soglia media',
              value: pricing.mediumDistanceMax,
              min: 3.0,
              max: 10.0,
              unit: 'km',
              onChanged: (v) => ref.read(riderPricingProvider.notifier).updateMediumDistanceMax(v),
            ),
            const SizedBox(height: 8),
            _PricingSlider(
              label: 'Bonus extra/km (lunga distanza)',
              value: pricing.longDistanceBonus,
              min: 0.10,
              max: 1.50,
              unit: '€/km',
              onChanged: (v) => ref.read(riderPricingProvider.notifier).updateLongDistanceBonus(v),
            ),

            const SizedBox(height: 32),

            // Distance tier examples
            _DistanceTierExamples(pricing: pricing),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Preview card showing estimated earnings with current settings
class _EarningsPreview extends StatelessWidget {
  final RiderPricing pricing;
  const _EarningsPreview({required this.pricing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final short = pricing.calculateBaseEarning(1.5);
    final medium = pricing.calculateBaseEarning(3.5);
    final long = pricing.calculateBaseEarning(7.0);
    final holdExample = pricing.calculateHoldCost(12);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.earningsGreen.withOpacity(0.15),
            AppColors.routeBlue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.earningsGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stima guadagni',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PreviewChip(label: '1.5 km', value: '€${short.toStringAsFixed(2)}', tag: 'corta'),
              _PreviewChip(label: '3.5 km', value: '€${medium.toStringAsFixed(2)}', tag: 'media'),
              _PreviewChip(label: '7.0 km', value: '€${long.toStringAsFixed(2)}', tag: 'lunga'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '+ €${holdExample.toStringAsFixed(2)} per 12 min attesa',
            style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  final String label;
  final String value;
  final String tag;
  const _PreviewChip({required this.label, required this.value, required this.tag});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.earningsGreen,
        )),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface)),
        Text(tag, style: GoogleFonts.inter(fontSize: 10, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.turboOrange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface,
          ), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _PricingSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _PricingSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.earningsGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(2)} $unit',
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.earningsGreen,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.earningsGreen,
            inactiveTrackColor: cs.surfaceContainerHighest,
            thumbColor: AppColors.earningsGreen,
            overlayColor: AppColors.earningsGreen.withOpacity(0.2),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) * 20).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _PricingIntSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;

  const _PricingIntSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.turboOrange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value $unit',
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.turboOrange,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.turboOrange,
            inactiveTrackColor: cs.surfaceContainerHighest,
            thumbColor: AppColors.turboOrange,
            overlayColor: AppColors.turboOrange.withOpacity(0.2),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}

/// Shows example calculations for each distance tier
class _DistanceTierExamples extends StatelessWidget {
  final RiderPricing pricing;
  const _DistanceTierExamples({required this.pricing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Come funziona', style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface,
          )),
          const SizedBox(height: 12),
          _TierRow(
            tier: 'Corta',
            desc: '0–${pricing.shortDistanceMax.toStringAsFixed(1)} km',
            detail: '€${pricing.ratePerKm.toStringAsFixed(2)}/km (min €${pricing.minDeliveryFee.toStringAsFixed(2)})',
            color: AppColors.earningsGreen,
          ),
          const SizedBox(height: 8),
          _TierRow(
            tier: 'Media',
            desc: '${pricing.shortDistanceMax.toStringAsFixed(1)}–${pricing.mediumDistanceMax.toStringAsFixed(1)} km',
            detail: '€${pricing.ratePerKm.toStringAsFixed(2)}/km',
            color: AppColors.routeBlue,
          ),
          const SizedBox(height: 8),
          _TierRow(
            tier: 'Lunga',
            desc: '>${pricing.mediumDistanceMax.toStringAsFixed(1)} km',
            detail: '€${pricing.ratePerKm.toStringAsFixed(2)}/km + €${pricing.longDistanceBonus.toStringAsFixed(2)}/km extra',
            color: AppColors.turboOrange,
          ),
          const SizedBox(height: 12),
          Divider(color: cs.surfaceContainerHighest),
          const SizedBox(height: 8),
          Text(
            'Attesa: primi ${pricing.holdFreeMinutes} min gratis, poi €${pricing.holdCostPerMin.toStringAsFixed(2)}/min',
            style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  final String tier;
  final String desc;
  final String detail;
  final Color color;
  const _TierRow({required this.tier, required this.desc, required this.detail, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 50,
          child: Text(tier, style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface,
          )),
        ),
        Flexible(
          child: Text(desc, style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(detail, style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
