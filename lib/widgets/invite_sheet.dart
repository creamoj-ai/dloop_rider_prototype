import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/tokens.dart';
import '../providers/user_provider.dart';
import '../providers/referral_provider.dart';
import '../services/referral_service.dart';

/// Bottom Sheet "Invita e guadagna" - wired to Supabase referrals table
class InviteSheet extends ConsumerWidget {
  const InviteSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const InviteSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final userAsync = ref.watch(currentUserProvider);
    final referralsAsync = ref.watch(referralsStreamProvider);

    // Generate referral code from user data
    final referralCode = userAsync.when(
      data: (user) => user != null
          ? ReferralService.generateReferralCode(user.firstName, user.lastName, user.id)
          : 'DLOOP0000',
      loading: () => '...',
      error: (_, __) => 'DLOOP0000',
    );

    final referrals = referralsAsync.when(
      data: (list) => list,
      loading: () => <Referral>[],
      error: (_, __) => <Referral>[],
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.turboOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: AppColors.turboOrange,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invita e guadagna',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Guadagnate entrambi',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Codice referral
                Text(
                  'Il tuo codice',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCodeBox(context, cs, referralCode),
                const SizedBox(height: 32),

                // Come funziona
                Text(
                  'Come funziona',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStep(cs, '1', 'Condividi il tuo codice', Icons.share),
                _buildStep(cs, '2', 'Il tuo amico si registra', Icons.person_add),
                _buildStep(cs, '3', 'Completa 5 consegne', Icons.delivery_dining),
                _buildStep(cs, '4', 'Ricevete €10 entrambi', Icons.euro, isLast: true),
                const SizedBox(height: 32),

                // CTA Condividi
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _shareInvite(context, referralCode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.turboOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'CONDIVIDI',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.share, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // I tuoi invitati
                Row(
                  children: [
                    Text(
                      'I tuoi invitati',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (referrals.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.earningsGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${referrals.length}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.earningsGreen,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInvitedList(cs, referrals),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCodeBox(BuildContext context, ColorScheme cs, String referralCode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.turboOrange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              referralCode,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.turboOrange,
                letterSpacing: 2,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: referralCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Codice copiato!',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  backgroundColor: AppColors.earningsGreen,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(
              'Copia',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.turboOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(ColorScheme cs, String number, String text, IconData icon, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.turboOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.turboOrange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: cs.onSurface,
              ),
            ),
          ),
          if (number == '4')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.earningsGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '€10',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.earningsGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInvitedList(ColorScheme cs, List<Referral> referrals) {
    if (referrals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Nessun invito ancora. Condividi il tuo codice!',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: referrals.asMap().entries.map((entry) {
          final index = entry.key;
          final referral = entry.value;
          final isLast = index == referrals.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: referral.isActive
                        ? AppColors.earningsGreen.withValues(alpha: 0.15)
                        : cs.onSurfaceVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: referral.isActive ? AppColors.earningsGreen : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        referral.referredName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            referral.isActive ? Icons.check_circle : Icons.hourglass_empty,
                            size: 12,
                            color: referral.isActive ? AppColors.earningsGreen : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            referral.isActive ? 'Attivo' : 'In attesa',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: referral.isActive ? AppColors.earningsGreen : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (referral.isActive)
                  Text(
                    '+€${referral.bonusAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.earningsGreen,
                    ),
                  )
                else
                  Text(
                    '-',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _shareInvite(BuildContext context, String referralCode) {
    final message = '''
Unisciti a dloop e guadagna consegnando!

Usa il mio codice: $referralCode

Riceverai €10 di bonus dopo le prime 5 consegne.

Scarica l'app: https://dloop.app/download
''';

    Share.share(message, subject: 'Unisciti a dloop!');
  }
}
