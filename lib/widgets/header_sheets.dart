import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';

/// Bottom sheet per la ricerca
class SearchSheet {
  static void show(BuildContext context, {String hint = 'Cerca...'}) {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Search input
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: GoogleFonts.inter(color: cs.onSurface, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(color: cs.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                      onPressed: () => controller.clear(),
                    ),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Recent searches
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text('Ricerche recenti', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Mock recent searches
              _buildSearchItem(cs, 'Via Roma 15', Icons.location_on),
              _buildSearchItem(cs, 'Pizzeria Mario', Icons.storefront),
              _buildSearchItem(cs, 'Ordine #1234', Icons.receipt),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSearchItem(ColorScheme cs, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface)),
        ],
      ),
    );
  }
}

/// Bottom sheet per le notifiche
class NotificationsSheet {
  static void show(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final notifications = [
      _NotificationData('Nuovo ordine disponibile', 'Pizzeria Mario - Via Roma', '2 min fa', Icons.delivery_dining, AppColors.turboOrange, true),
      _NotificationData('Commissione ricevuta', '+€2.40 da Marco R.', '15 min fa', Icons.euro, AppColors.earningsGreen, true),
      _NotificationData('Obiettivo raggiunto!', 'Hai completato 10 consegne oggi', '1h fa', Icons.emoji_events, AppColors.statsGold, false),
      _NotificationData('Nuova zona bonus', 'Centro: +20% fino alle 14:00', '2h fa', Icons.location_on, AppColors.routeBlue, false),
      _NotificationData('Vendita MyShop', 'Anna V. ha acquistato Energy Box', '3h fa', Icons.shopping_cart, AppColors.bonusPurple, false),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.notifications, color: AppColors.turboOrange, size: 22),
                  const SizedBox(width: 10),
                  Text('Notifiche', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Segna lette', style: GoogleFonts.inter(fontSize: 12, color: AppColors.routeBlue)),
                  ),
                ],
              ),
            ),
            // Notifications list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return _buildNotificationTile(cs, n);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildNotificationTile(ColorScheme cs, _NotificationData n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: n.isUnread ? n.color.withValues(alpha: 0.1) : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: n.isUnread ? Border.all(color: n.color.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: n.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(n.icon, color: n.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(n.subtitle, style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(n.time, style: GoogleFonts.inter(fontSize: 10, color: cs.onSurfaceVariant)),
              if (n.isUnread) ...[
                const SizedBox(height: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: n.color, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationData {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;
  final bool isUnread;
  _NotificationData(this.title, this.subtitle, this.time, this.icon, this.color, this.isUnread);
}

/// Bottom sheet per quick actions
class QuickActionsSheet {
  static void show(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.turboOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.bolt, color: AppColors.turboOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Azioni rapide', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
              ],
            ),
          ),
          // Actions grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildAction(context, cs, 'Vai online', Icons.power_settings_new, AppColors.earningsGreen, () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stato: Online'), backgroundColor: AppColors.earningsGreen),
                  );
                }),
                const SizedBox(width: 10),
                _buildAction(context, cs, 'Pausa', Icons.pause_circle, AppColors.statsGold, () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pausa attivata'), backgroundColor: AppColors.statsGold),
                  );
                }),
                const SizedBox(width: 10),
                _buildAction(context, cs, 'SOS', Icons.warning_amber, AppColors.urgentRed, () {
                  Navigator.pop(context);
                  _showSOSDialog(context);
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildAction(context, cs, 'Navigatore', Icons.navigation, AppColors.routeBlue, () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Apertura navigatore...'), backgroundColor: AppColors.routeBlue),
                  );
                }),
                const SizedBox(width: 10),
                _buildAction(context, cs, 'Chiama', Icons.phone, AppColors.bonusPurple, () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chiamata supporto...'), backgroundColor: AppColors.bonusPurple),
                  );
                }),
                const SizedBox(width: 10),
                _buildAction(context, cs, 'Report', Icons.report_problem, AppColors.turboOrange, () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Apri report problema'), backgroundColor: AppColors.turboOrange),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Widget _buildAction(BuildContext context, ColorScheme cs, String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface)),
            ],
          ),
        ),
      ),
    );
  }

  static void _showSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.urgentRed),
            const SizedBox(width: 10),
            Text('SOS Emergenza', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text('Vuoi inviare una richiesta di aiuto al supporto?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SOS inviato! Il supporto ti contatterà'), backgroundColor: AppColors.urgentRed),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.urgentRed),
            child: Text('Invia SOS', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
