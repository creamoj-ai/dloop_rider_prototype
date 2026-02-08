import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/earnings_provider.dart';

/// Card che mostra il breakdown dei guadagni di oggi
class EarningsBreakdownCard extends ConsumerWidget {
  const EarningsBreakdownCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(todayBreakdownProvider);
    final earnings = ref.watch(earningsProvider);

    return Card(
      color: const Color(0xFF1E1E22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart, color: Colors.purpleAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Composizione Guadagni',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${earnings.ordersCount} ordini',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Breakdown items
            _BreakdownItem(
              label: 'Base (€/km)',
              amount: breakdown['base'] ?? 0,
              color: Colors.blueAccent,
              icon: Icons.route,
            ),
            const SizedBox(height: 12),
            _BreakdownItem(
              label: 'Rush Hour Bonus',
              amount: breakdown['rush'] ?? 0,
              color: Colors.orange,
              icon: Icons.local_fire_department,
            ),
            const SizedBox(height: 12),
            _BreakdownItem(
              label: 'Attesa ristorante',
              amount: breakdown['hold'] ?? 0,
              color: Colors.deepPurpleAccent,
              icon: Icons.hourglass_bottom,
            ),
            const SizedBox(height: 12),
            _BreakdownItem(
              label: 'Performance Bonus',
              amount: breakdown['bonus'] ?? 0,
              color: Colors.amber,
              icon: Icons.star,
            ),
            const SizedBox(height: 12),
            _BreakdownItem(
              label: 'Mance',
              amount: breakdown['tips'] ?? 0,
              color: Colors.greenAccent,
              icon: Icons.volunteer_activism,
            ),

            const Divider(height: 32, color: Color(0xFF2A2A2E)),

            // Totale
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTALE OGGI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '€${(breakdown['total'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),

            // Stats extra
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                  label: '€/ordine',
                  value: '€${earnings.avgPerOrder.toStringAsFixed(1)}',
                ),
                _StatChip(
                  label: '€/ora',
                  value: '€${earnings.hourlyRate.toStringAsFixed(1)}',
                ),
                _StatChip(
                  label: 'km totali',
                  value: '${earnings.totalKmToday.toStringAsFixed(1)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Singola riga del breakdown
class _BreakdownItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _BreakdownItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Calcola la percentuale per la barra (max 100€ per visualizzazione)
    final percentage = (amount / 50).clamp(0.0, 1.0);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '€${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: amount > 0 ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 4,
                  backgroundColor: const Color(0xFF2A2A2E),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Chip statistiche
class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
