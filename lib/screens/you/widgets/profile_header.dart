import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/tokens.dart';
import '../../../providers/user_provider.dart';

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return _buildPlaceholder();
        }

        // Calcola livello basato su ordini (ogni 100 ordini = 1 livello)
        final level = (user.totalOrders / 100).floor() + 1;
        final xpCurrent = user.totalOrders % 100;
        final xpNext = 100;

        // Formatta data di creazione
        final memberSince = DateFormat('MMM yyyy', 'it_IT').format(user.createdAt);

        return Column(
          children: [
            // Avatar (con iniziali se non c'è immagine)
            user.avatarUrl != null
                ? CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(user.avatarUrl!),
                  )
                : CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF252529),
                    child: Text(
                      user.initials,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.bonusPurple,
                      ),
                    ),
                  ),
            const SizedBox(height: 12),
            // Nome completo
            Text(
              user.fullName,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            // Livello
            Text(
              'Livello $level Rider',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.bonusPurple,
              ),
            ),
            const SizedBox(height: 12),
            // Barra progresso XP
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$xpCurrent XP',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$xpNext XP',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: xpCurrent / xpNext,
                      minHeight: 6,
                      backgroundColor: const Color(0xFF252529),
                      valueColor: const AlwaysStoppedAnimation(AppColors.bonusPurple),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Membro dal...
            Text(
              'Membro dal $memberSince',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ],
        );
      },
      loading: () => _buildPlaceholder(),
      error: (error, stack) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundColor: Color(0xFF252529),
          child: Icon(Icons.person, size: 40, color: Color(0xFF9E9E9E)),
        ),
        const SizedBox(height: 12),
        Text(
          'Caricamento...',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
