import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';
import '../../../providers/rest_mode_provider.dart';
import '../../../providers/session_provider.dart';

class WellnessCard extends ConsumerStatefulWidget {
  const WellnessCard({super.key});

  @override
  ConsumerState<WellnessCard> createState() => _WellnessCardState();
}

class _WellnessCardState extends ConsumerState<WellnessCard> {
  bool _isExpanded = false;
  bool _isResting = false;
  int? _selectedMinutes;
  int _remainingSeconds = 0;
  Timer? _timer;
  int _breakReduction = 0; // cumulative break stress reduction

  double _computeStressIndex(ActiveSessionState session) {
    if (!session.hasActiveSession || session.startTime == null) {
      return 0.1; // No session, fully rested
    }
    final activeHours = DateTime.now().difference(session.startTime!).inMinutes / 60.0;
    double base;
    if (activeHours < 2) {
      base = 0.15;
    } else if (activeHours < 4) {
      base = 0.35;
    } else if (activeHours < 6) {
      base = 0.55;
    } else if (activeHours < 8) {
      base = 0.75;
    } else {
      base = 0.95;
    }
    // Reduce by completed breaks (each reduces by 0.15)
    return (base - _breakReduction * 0.15).clamp(0.05, 1.0);
  }

  String _computeActiveTime(ActiveSessionState session) {
    if (!session.hasActiveSession || session.startTime == null) {
      return '0h 0m';
    }
    final elapsed = DateTime.now().difference(session.startTime!);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Color _stressColor(double stressIndex) {
    if (_isResting) return AppColors.routeBlue;
    if (stressIndex < 0.4) return AppColors.earningsGreen;
    if (stressIndex < 0.7) return AppColors.statsGold;
    return AppColors.urgentRed;
  }

  String _stressLabel(double stressIndex) {
    if (_isResting) return 'RIPOSO';
    if (stressIndex < 0.4) return 'OTTIMO';
    if (stressIndex < 0.7) return 'BUONO';
    return 'RIPOSA';
  }

  int _energyPercent(double stressIndex) => (100 - stressIndex * 100).toInt();

  String get _remainingTimeFormatted {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startBreak(int minutes) {
    setState(() {
      _isResting = true;
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _isExpanded = true;
    });

    // Update global rest mode
    ref.read(restModeProvider.notifier).startRest(minutes);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
        ref.read(restModeProvider.notifier).updateTime(_remainingSeconds);
      } else {
        _endBreak(completed: true);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.self_improvement, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Riposo attivato - $minutes min')),
          ],
        ),
        backgroundColor: AppColors.routeBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _endBreak({bool completed = false}) {
    _timer?.cancel();
    setState(() {
      _isResting = false;
      _selectedMinutes = null;
      _remainingSeconds = 0;
      if (completed) _breakReduction++;
    });

    // End global rest mode
    ref.read(restModeProvider.notifier).endRest();

    if (completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Pausa completata!')),
            ],
          ),
          backgroundColor: AppColors.earningsGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = ref.watch(activeSessionProvider);
    final stressIndex = _computeStressIndex(session);
    final activeTime = _computeActiveTime(session);
    final color = _stressColor(stressIndex);
    final label = _stressLabel(stressIndex);
    final energy = _energyPercent(stressIndex);

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(_isExpanded ? 16 : 14),
        decoration: BoxDecoration(
          color: _isResting ? AppColors.routeBlue.withValues(alpha: 0.1) : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: _isResting ? 0.5 : 0.2),
            width: _isResting ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(cs, stressIndex, color, label, energy),
            if (_isExpanded) ...[
              const SizedBox(height: 14),
              _isResting ? _buildRestingContent(cs) : _buildActiveContent(cs, stressIndex, activeTime, color, energy),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, double stressIndex, Color color, String label, int energy) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Icon(
              _isResting ? Icons.bedtime : Icons.self_improvement,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              _isResting ? 'PAUSA' : 'BENESSERE',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.8,
              ),
            ),
            if (!_isExpanded) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _isResting
                    ? Text(
                        _remainingTimeFormatted,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.routeBlue,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: 1 - stressIndex,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 5,
                        ),
                      ),
              ),
              if (!_isResting) ...[
                const SizedBox(width: 6),
                Text(
                  '$energy%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ] else
              const Spacer(),
            const SizedBox(width: 4),
            Flexible(
              flex: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 2),
            AnimatedRotation(
              duration: const Duration(milliseconds: 250),
              turns: _isExpanded ? 0.5 : 0,
              child: Icon(Icons.keyboard_arrow_down, color: cs.onSurfaceVariant, size: 18),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRestingContent(ColorScheme cs) {
    final progress = _selectedMinutes != null
        ? 1 - (_remainingSeconds / (_selectedMinutes! * 60))
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.routeBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _remainingTimeFormatted,
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: AppColors.routeBlue,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tempo rimanente',
                style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation(AppColors.routeBlue),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton(
            onPressed: () => _endBreak(completed: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.urgentRed,
              side: BorderSide(color: AppColors.urgentRed.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.zero,
            ),
            child: Text('TERMINA', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveContent(ColorScheme cs, double stressIndex, String activeTime, Color color, int energy) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Energia', style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
                      Text('$energy%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: 1 - stressIndex,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Attivo', style: GoogleFonts.inter(fontSize: 10, color: cs.onSurfaceVariant)),
                Text(activeTime, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.coffee, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('Pausa:', style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
            const Spacer(),
            _BreakBtn(min: 5, sel: _selectedMinutes, onTap: () => _startBreak(5)),
            const SizedBox(width: 6),
            _BreakBtn(min: 10, sel: _selectedMinutes, rec: true, onTap: () => _startBreak(10)),
            const SizedBox(width: 6),
            _BreakBtn(min: 20, sel: _selectedMinutes, onTap: () => _startBreak(20)),
          ],
        ),
      ],
    );
  }
}

class _BreakBtn extends StatelessWidget {
  final int min;
  final int? sel;
  final bool rec;
  final VoidCallback onTap;

  const _BreakBtn({required this.min, this.sel, this.rec = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSel = sel == min;
    final color = isSel ? AppColors.routeBlue : (rec ? AppColors.earningsGreen : cs.onSurfaceVariant);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isSel || rec) ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: isSel ? 0.8 : 0.4), width: isSel ? 2 : 1),
        ),
        child: Text("$min'", style: GoogleFonts.inter(fontSize: 11, fontWeight: (rec || isSel) ? FontWeight.w700 : FontWeight.w500, color: color)),
      ),
    );
  }
}
