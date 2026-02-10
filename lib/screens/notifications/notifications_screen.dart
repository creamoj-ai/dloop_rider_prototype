import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/notification.dart';
import '../../providers/notifications_provider.dart';
import '../../theme/tokens.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Text(
          'Notifiche',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationsProvider.notifier).markAllAsRead(),
              child: Text(
                'Segna tutte lette',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.turboOrange,
                ),
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.turboOrange))
          : state.notifications.isEmpty
              ? _buildEmptyState(cs)
              : _buildNotificationsList(context, ref, state.notifications, cs),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: cs.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Nessuna notifica',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Le tue notifiche appariranno qui',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: cs.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    WidgetRef ref,
    List<AppNotification> notifications,
    ColorScheme cs,
  ) {
    // Group by date
    final grouped = <String, List<AppNotification>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final n in notifications) {
      final date = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      String label;
      if (date == today) {
        label = 'Oggi';
      } else if (date == yesterday) {
        label = 'Ieri';
      } else {
        label = DateFormat('d MMMM yyyy', 'it_IT').format(n.createdAt);
      }
      grouped.putIfAbsent(label, () => []).add(n);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                entry.key,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            ...entry.value.map((n) => _NotificationTile(
              notification: n,
              onTap: () {
                if (!n.isRead) {
                  ref.read(notificationsProvider.notifier).markAsRead(n.id);
                }
              },
            )),
          ],
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _colorForType(notification.type);
    final icon = _iconForType(notification.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? cs.surfaceContainerHighest.withOpacity(0.3)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Radii.md),
          border: notification.isRead
              ? null
              : Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(notification.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: cs.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
                if (!notification.isRead) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.turboOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'ora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m fa';
    if (diff.inHours < 24) return '${diff.inHours}h fa';
    return DateFormat('HH:mm', 'it_IT').format(dt);
  }

  static IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return Icons.delivery_dining;
      case NotificationType.orderAccepted:
      case NotificationType.orderPickedUp:
        return Icons.local_shipping;
      case NotificationType.orderDelivered:
        return Icons.check_circle;
      case NotificationType.orderCancelled:
        return Icons.cancel;
      case NotificationType.newEarning:
        return Icons.euro;
      case NotificationType.dailyTargetReached:
        return Icons.flag;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.system:
        return Icons.info;
    }
  }

  static Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return AppColors.turboOrange;
      case NotificationType.orderAccepted:
      case NotificationType.orderPickedUp:
        return AppColors.routeBlue;
      case NotificationType.orderDelivered:
        return AppColors.earningsGreen;
      case NotificationType.orderCancelled:
        return AppColors.urgentRed;
      case NotificationType.newEarning:
        return AppColors.earningsGreen;
      case NotificationType.dailyTargetReached:
        return AppColors.statsGold;
      case NotificationType.achievement:
        return AppColors.bonusPurple;
      case NotificationType.system:
        return AppColors.routeBlue;
    }
  }
}
