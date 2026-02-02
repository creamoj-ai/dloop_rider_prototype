import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      bottomNavigationBar: BottomNavigationBar(
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
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF6B00),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF1A1A1E),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Money'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'You'),
        ],
      ),
    );
  }
}
