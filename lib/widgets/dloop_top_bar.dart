import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';

class DloopTopBar extends StatelessWidget {
  final String? avatarUrl;
  final bool isOnline;
  final int notificationCount;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onQuickActionTap;
  final String searchHint;

  const DloopTopBar({
    super.key,
    this.avatarUrl,
    this.isOnline = false,
    this.notificationCount = 0,
    this.onSearchTap,
    this.onNotificationTap,
    this.onQuickActionTap,
    this.searchHint = 'Cerca zone, ordini...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          // Avatar con status indicator
          _AvatarWithStatus(
            avatarUrl: avatarUrl,
            isOnline: isOnline,
            onTap: () => context.go('/you'),
          ),
          const SizedBox(width: 8),

          // Quick action (bolt/flash) - next to profile
          _IconButtonWithBadge(
            icon: Icons.bolt,
            badgeCount: 0,
            isAccent: true,
            onTap: onQuickActionTap,
          ),
          const SizedBox(width: 12),

          // Search bar (espandibile)
          Expanded(
            child: _SearchBar(
              hint: searchHint,
              onTap: onSearchTap,
            ),
          ),
          const SizedBox(width: 12),

          // Notification bell
          _IconButtonWithBadge(
            icon: Icons.notifications_outlined,
            badgeCount: notificationCount,
            onTap: onNotificationTap,
          ),
        ],
      ),
    );
  }
}

class _AvatarWithStatus extends StatelessWidget {
  final String? avatarUrl;
  final bool isOnline;
  final VoidCallback? onTap;

  const _AvatarWithStatus({
    this.avatarUrl,
    required this.isOnline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isOnline ? AppColors.earningsGreen : Colors.grey.shade600,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultAvatar(),
                    )
                  : _defaultAvatar(),
            ),
          ),
          // Status dot
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.earningsGreen : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0D0D0F),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: const Color(0xFF2A2A2E),
      child: const Icon(
        Icons.person,
        color: Colors.grey,
        size: 24,
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;

  const _SearchBar({
    required this.hint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1E),
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(
            color: const Color(0xFF2A2A2E),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hint,
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButtonWithBadge extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final bool isAccent;
  final VoidCallback? onTap;

  const _IconButtonWithBadge({
    required this.icon,
    required this.badgeCount,
    this.isAccent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isAccent
              ? AppColors.turboOrange.withOpacity(0.15)
              : const Color(0xFF1A1A1E),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: isAccent ? AppColors.turboOrange : Colors.white70,
              size: 22,
            ),
            // Badge
            if (badgeCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.urgentRed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
