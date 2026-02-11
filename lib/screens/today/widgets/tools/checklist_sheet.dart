import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/tokens.dart';
import '../../../../services/preferences_service.dart';

class ChecklistSheet extends StatefulWidget {
  const ChecklistSheet({super.key});

  @override
  State<ChecklistSheet> createState() => _ChecklistSheetState();
}

class _ChecklistSheetState extends State<ChecklistSheet> {
  static const _allItems = [
    ('phone_charged', 'Telefono carico', Icons.battery_charging_full),
    ('bag_clean', 'Borsa termica pulita', Icons.shopping_bag),
    ('vehicle_ok', 'Veicolo controllato', Icons.two_wheeler),
    ('notifications_on', 'Notifiche attive', Icons.notifications_active),
    ('documents_ok', 'Documenti in regola', Icons.badge),
  ];

  final Set<String> _checked = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    try {
      final prefs = await PreferencesService.getPreferences();
      final checklist = prefs['checklist'] as List<dynamic>? ?? [];
      setState(() {
        _checked.addAll(checklist.map((e) => e.toString()));
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(String key) async {
    setState(() {
      if (_checked.contains(key)) {
        _checked.remove(key);
      } else {
        _checked.add(key);
      }
    });
    // Save to DB
    try {
      await PreferencesService.updateChecklist(_checked.toList());
    } catch (_) {}
  }

  double get _progress => _allItems.isEmpty ? 0 : _checked.length / _allItems.length;
  bool get _allDone => _checked.length == _allItems.length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator(color: AppColors.turboOrange)),
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
                  color: AppColors.turboOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.checklist, color: AppColors.turboOrange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Checklist Pre-Turno', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
                    Text('${_checked.length}/${_allItems.length} completati', style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              if (_allDone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.earningsGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('PRONTO!', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.earningsGreen)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                _allDone ? AppColors.earningsGreen : AppColors.turboOrange,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Checklist items
          ..._allItems.map((item) {
            final isChecked = _checked.contains(item.$1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _toggle(item.$1),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isChecked
                        ? AppColors.earningsGreen.withValues(alpha: 0.08)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: isChecked
                        ? Border.all(color: AppColors.earningsGreen.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(item.$3, size: 20, color: isChecked ? AppColors.earningsGreen : cs.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isChecked ? AppColors.earningsGreen : cs.onSurface,
                            decoration: isChecked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      Icon(
                        isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 22,
                        color: isChecked ? AppColors.earningsGreen : cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
