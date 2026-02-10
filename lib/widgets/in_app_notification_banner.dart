import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notification.dart';
import '../theme/tokens.dart';

/// Data for a single banner notification
class BannerNotificationData {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final VoidCallback? onTap;

  BannerNotificationData({
    required this.id,
    required this.title,
    this.body = '',
    this.type = NotificationType.system,
    this.onTap,
  });
}

/// Controller for in-app notification banners (queue-based)
class InAppNotificationController extends ChangeNotifier {
  final List<BannerNotificationData> _queue = [];

  List<BannerNotificationData> get notifications => List.unmodifiable(_queue);

  void show({
    required String title,
    String body = '',
    NotificationType type = NotificationType.system,
    VoidCallback? onTap,
  }) {
    _queue.add(BannerNotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      onTap: onTap,
    ));
    notifyListeners();
  }

  void dismiss(String id) {
    _queue.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clear() {
    _queue.clear();
    notifyListeners();
  }
}

/// Icon and color for each notification type
IconData _iconForType(NotificationType type) {
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

Color _colorForType(NotificationType type) {
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

/// Compact banner notification that slides in from the top
class _NotificationBanner extends StatefulWidget {
  final BannerNotificationData data;
  final VoidCallback onDismiss;

  const _NotificationBanner({
    super.key,
    required this.data,
    required this.onDismiss,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(widget.data.type);
    final icon = _iconForType(widget.data.type);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: () {
            widget.data.onTap?.call();
            _dismiss();
          },
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
              _dismiss();
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E22),
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.data.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.data.body.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.data.body,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white30, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay that shows banner notifications at the top of the screen
class InAppNotificationOverlay extends StatelessWidget {
  final InAppNotificationController controller;
  final Widget child;

  const InAppNotificationOverlay({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.notifications.isEmpty) {
              return const SizedBox.shrink();
            }
            final notification = controller.notifications.first;
            return Positioned(
              top: MediaQuery.of(context).padding.top + 4,
              left: 0,
              right: 0,
              child: _NotificationBanner(
                key: ValueKey(notification.id),
                data: notification,
                onDismiss: () => controller.dismiss(notification.id),
              ),
            );
          },
        ),
      ],
    );
  }
}
