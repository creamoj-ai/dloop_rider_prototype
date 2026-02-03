import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/money')) return 1;
    if (location.startsWith('/market')) return 2;
    if (location.startsWith('/you')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _selectedIndex(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: child,
      bottomNavigationBar: _AnimatedBottomNav(
        currentIndex: index,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/today');
            case 1:
              context.go('/money');
            case 2:
              context.go('/market');
            case 3:
              context.go('/you');
          }
        },
      ),
    );
  }
}

class _AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AnimatedBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  static const _selectedColor = Color(0xFFFF6B00);
  static const _bgColor = Color(0xFF1A1A1E);
  static const _indicatorWidthFixed = 32.0;

  // Mock badges - in produzione verrebbero da stato/provider
  static const List<int> _badges = [0, 2, 0, 1]; // Today, Money, Market, You

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: _bgColor,
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A2E), width: 0.5),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 4;
          final indicatorLeft = (tabWidth * currentIndex) + (tabWidth - _indicatorWidthFixed) / 2;

          return Stack(
            children: [
              // Tab items
              Row(
                children: [
                  _NavItem(
                    icon: Icons.bolt,
                    label: 'Today',
                    isSelected: currentIndex == 0,
                    badge: _badges[0],
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: Icons.wallet,
                    label: 'Money',
                    isSelected: currentIndex == 1,
                    badge: _badges[1],
                    onTap: () => onTap(1),
                  ),
                  _NavItem(
                    icon: Icons.shopping_cart,
                    label: 'Market',
                    isSelected: currentIndex == 2,
                    badge: _badges[2],
                    onTap: () => onTap(2),
                  ),
                  _NavItem(
                    icon: Icons.person,
                    label: 'You',
                    isSelected: currentIndex == 3,
                    badge: _badges[3],
                    onTap: () => onTap(3),
                  ),
                ],
              ),
              // Sliding indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                bottom: 6,
                left: indicatorLeft,
                child: Container(
                  width: _indicatorWidthFixed,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? const Color(0xFFFF6B00)
        : Colors.grey;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  // Badge dot
                  if (badge > 0)
                    Positioned(
                      right: -4,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B00),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
