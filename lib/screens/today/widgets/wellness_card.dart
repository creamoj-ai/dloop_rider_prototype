import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class WellnessCard extends StatefulWidget {
  const WellnessCard({super.key});

  @override
  State<WellnessCard> createState() => _WellnessCardState();
}

class _WellnessCardState extends State<WellnessCard> {
  bool _isExpanded = false;

  // Mock data - in produzione verrebbe da Supabase
  static const double _stressIndex = 0.62;
  static const String _activeTime = '3h 12m';
  static const int _suggestedBreak = 10;

  Color get _stressColor {
    if (_stressIndex < 0.4) return AppColors.earningsGreen;
    if (_stressIndex < 0.7) return AppColors.statsGold;
    return AppColors.urgentRed;
  }

  String get _stressLabel {
    if (_stressIndex < 0.4) return 'OTTIMO';
    if (_stressIndex < 0.7) return 'BUONO';
    return 'RIPOSA';
  }

  int get _energyPercent => (100 - _stressIndex * 100).toInt();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(_isExpanded ? 20 : 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _stressColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Header row (sempre visibile)
            _buildHeader(cs),

            // Contenuto espandibile
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: _buildExpandedContent(cs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Row(
      children: [
        Icon(
          Icons.self_improvement,
          color: _stressColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'WELLNESS',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _stressColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        // Mini progress bar (visibile quando chiuso)
        if (!_isExpanded) ...[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: 1 - _stressIndex,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(_stressColor),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$_energyPercent%',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _stressColor,
            ),
          ),
        ],
        if (_isExpanded) const Spacer(),
        const SizedBox(width: 8),
        // Badge stato
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _stressColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _stressLabel,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _stressColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Expand/collapse icon
        AnimatedRotation(
          duration: const Duration(milliseconds: 250),
          turns: _isExpanded ? 0.5 : 0,
          child: Icon(
            Icons.keyboard_arrow_down,
            color: cs.onSurfaceVariant,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(ColorScheme cs) {
    return Column(
      children: [
        const SizedBox(height: 16),

        // Stress bar (expanded)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Energia',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '$_energyPercent%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _stressColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 1 - _stressIndex,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(_stressColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Active time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Attivo',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _activeTime,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quick break row
        Row(
          children: [
            Icon(
              Icons.coffee,
              size: 14,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Pausa consigliata: $_suggestedBreak min',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            // Quick break buttons
            _BreakButton(minutes: 5, onTap: () => _startBreak(5)),
            const SizedBox(width: 8),
            _BreakButton(minutes: 10, isRecommended: true, onTap: () => _startBreak(10)),
            const SizedBox(width: 8),
            _BreakButton(minutes: 20, onTap: () => _startBreak(20)),
          ],
        ),
      ],
    );
  }

  void _startBreak(int minutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.timer, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Pausa di $minutes minuti avviata'),
          ],
        ),
        backgroundColor: AppColors.earningsGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _BreakButton extends StatelessWidget {
  final int minutes;
  final bool isRecommended;
  final VoidCallback onTap;

  const _BreakButton({
    required this.minutes,
    this.isRecommended = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isRecommended ? AppColors.earningsGreen : cs.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isRecommended ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(isRecommended ? 0.5 : 0.3),
            width: 1,
          ),
        ),
        child: Text(
          "$minutes'",
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isRecommended ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }
}
