import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundColor: Color(0xFF252529),
          child: Icon(Icons.person, size: 40, color: Color(0xFF9E9E9E)),
        ),
        const SizedBox(height: 12),
        Text(
          'Marco Rossi',
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'Livello 12 Rider',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.bonusPurple),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('2.450 XP', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text('3.000 XP', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E))),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 2450 / 3000,
                  minHeight: 6,
                  backgroundColor: const Color(0xFF252529),
                  valueColor: const AlwaysStoppedAnimation(AppColors.bonusPurple),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Membro dal Gen 2024',
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E)),
        ),
      ],
    );
  }
}
