import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/dloop_card.dart';
import '../../../providers/user_provider.dart';
import '../../../services/push_notification_service.dart';

class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return DloopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 18, color: AppColors.routeBlue),
              const SizedBox(width: 8),
              Text(
                'ACCOUNT',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _menuItem(context, ref, Icons.settings, 'Impostazioni', null),
          _menuItem(context, ref, Icons.support_agent, 'Supporto', null),
          _menuItem(context, ref, Icons.logout, 'Logout', Colors.red),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, WidgetRef ref, IconData icon, String label, Color? color) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? Colors.white, size: 20),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color ?? Colors.white,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: const Color(0xFF9E9E9E),
        size: 20,
      ),
      onTap: () {
        if (label == 'Logout') {
          _handleLogout(context, ref);
        } else if (label == 'Supporto') {
          context.push('/you/support');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(label)),
          );
        }
      },
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    final rootContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Conferma Logout',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Sei sicuro di voler uscire?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annulla',
              style: GoogleFonts.inter(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Pulisci il provider
              ref.read(currentUserProvider.notifier).logout();

              // Remove FCM token before logout
              await PushNotificationService.removeToken();

              // Logout da Supabase Auth
              await Supabase.instance.client.auth.signOut();

              if (rootContext.mounted) {
                rootContext.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
