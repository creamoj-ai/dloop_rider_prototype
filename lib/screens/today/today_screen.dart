import 'package:flutter/material.dart';
import '../../widgets/dloop_top_bar.dart';
import 'widgets/kpi_strip.dart';
import 'widgets/active_mode_card.dart';
import 'widgets/hot_zones.dart';
import 'widgets/wellness_card.dart';
import 'widgets/quick_actions_grid.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _isOnline = true;
  int _notificationCount = 3;

  void _showSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _SearchSheet(),
    );
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifiche in arrivo...')),
    );
  }

  void _toggleOnline() {
    setState(() {
      _isOnline = !_isOnline;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isOnline ? 'Sei online!' : 'Sei offline'),
        backgroundColor: _isOnline ? Colors.green : Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top Bar stile Revolut
          DloopTopBar(
            isOnline: _isOnline,
            notificationCount: _notificationCount,
            onSearchTap: _showSearch,
            onNotificationTap: _showNotifications,
            onQuickActionTap: _toggleOnline,
            searchHint: 'Cerca zone, ordini...',
          ),
          // Contenuto scrollabile
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KpiStrip(),
                      SizedBox(height: 24),
                      ActiveModeCard(),
                      SizedBox(height: 24),
                      HotZones(),
                      SizedBox(height: 24),
                      QuickActionsGrid(),
                      SizedBox(height: 24),
                      WellnessCard(),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchSheet extends StatelessWidget {
  const _SearchSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
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
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Search input
              TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cerca zone, ordini, guadagni...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Quick filters
              Text(
                'Ricerche rapide',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickFilter(label: 'Zone calde', icon: Icons.local_fire_department),
                  _QuickFilter(label: 'Ordini oggi', icon: Icons.receipt_long),
                  _QuickFilter(label: 'Guadagni settimana', icon: Icons.trending_up),
                  _QuickFilter(label: 'Bonus attivi', icon: Icons.card_giftcard),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Recenti',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _RecentSearchItem(text: 'Zona Centro Milano'),
              _RecentSearchItem(text: 'Ordine #12847'),
              _RecentSearchItem(text: 'Bonus weekend'),
            ],
          ),
        );
      },
    );
  }
}

class _QuickFilter extends StatelessWidget {
  final String label;
  final IconData icon;

  const _QuickFilter({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFF6B00)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RecentSearchItem extends StatelessWidget {
  final String text;

  const _RecentSearchItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.history, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Icon(Icons.north_west, size: 16, color: Colors.grey.shade600),
        ],
      ),
    );
  }
}
