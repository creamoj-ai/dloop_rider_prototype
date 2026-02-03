import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class ActiveModeCard extends StatelessWidget {
  const ActiveModeCard({super.key});

  // Hardcoded to "delivering" mode
  static const String _mode = 'delivering';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModeChip(),
          const SizedBox(height: 20),
          _buildContent(cs),
          const SizedBox(height: 20),
          _buildCta(context),
        ],
      ),
    );
  }

  Color get _accentColor {
    switch (_mode) {
      case 'delivering':
        return AppColors.turboOrange;
      case 'growing':
        return AppColors.earningsGreen;
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String get _chipLabel {
    switch (_mode) {
      case 'delivering':
        return 'DELIVERING';
      case 'growing':
        return 'GROWING';
      default:
        return 'RESTING';
    }
  }

  Widget _buildModeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _chipLabel,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _accentColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme cs) {
    switch (_mode) {
      case 'delivering':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prossimo ordine: Via Roma 15',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.straighten, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '1.2 km',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 20),
                Icon(Icons.euro, size: 14, color: AppColors.earningsGreen),
                const SizedBox(width: 4),
                Text(
                  '€ 4.80',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.earningsGreen,
                  ),
                ),
              ],
            ),
          ],
        );
      case 'growing':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network attivo',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '3 dealer online  •  € 2.40/h',
              style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'In pausa',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Riprendi quando vuoi',
              style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        );
    }
  }

  Widget _buildCta(BuildContext context) {
    final String label;
    final Color bgColor;
    final Color textColor;
    final bool isOutline;

    switch (_mode) {
      case 'delivering':
        label = 'ACCETTA E VAI';
        bgColor = AppColors.turboOrange;
        textColor = Colors.white;
        isOutline = false;
        break;
      case 'growing':
        label = 'VEDI NETWORK';
        bgColor = AppColors.earningsGreen;
        textColor = Colors.white;
        isOutline = false;
        break;
      default:
        label = 'RIPRENDI';
        bgColor = Colors.transparent;
        textColor = Colors.white;
        isOutline = true;
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: isOutline
          ? OutlinedButton(
              onPressed: () => _showSnack(context, label),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: textColor,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: () => _showSnack(context, label),
              style: ElevatedButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  if (_mode == 'delivering') ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ],
              ),
            ),
    );
  }

  void _showSnack(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action tapped — prototype only'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
