import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/earnings_provider.dart';

/// Widget che mostra il progresso verso l'obiettivo giornaliero €80
class DailyTargetWidget extends ConsumerWidget {
  final bool compact;

  const DailyTargetWidget({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(earningsProvider);
    final target = earnings.dailyTarget;

    if (compact) {
      return _buildCompact(target);
    }

    return _buildFull(target, earnings);
  }

  Widget _buildCompact(target) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular progress
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: target.progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(
                    target.isComplete ? Colors.greenAccent : Colors.blueAccent,
                  ),
                ),
                Center(
                  child: Text(
                    '${target.progressPercent}%',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '€${target.currentAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'di €${target.targetAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFull(target, EarningsState earnings) {
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
                    Icon(Icons.flag, color: Colors.blueAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Obiettivo Giornaliero',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                _StatusBadge(isComplete: target.isComplete),
              ],
            ),
            const SizedBox(height: 16),

            // Importi
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '€${target.currentAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: target.isComplete ? Colors.greenAccent : Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '/ €${target.targetAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: target.progress,
                minHeight: 10,
                backgroundColor: const Color(0xFF2A2A2E),
                valueColor: AlwaysStoppedAnimation(
                  target.isComplete ? Colors.greenAccent : Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(
                  label: 'Ordini',
                  value: '${target.ordersCompleted}',
                  icon: Icons.receipt_long,
                ),
                _StatItem(
                  label: 'Media',
                  value: '€${target.avgPerOrder.toStringAsFixed(1)}',
                  icon: Icons.analytics,
                ),
                _StatItem(
                  label: 'Mancano',
                  value: target.isComplete
                      ? '✓'
                      : '€${target.remaining.toStringAsFixed(0)}',
                  icon: Icons.trending_up,
                ),
              ],
            ),

            // Messaggio motivazionale
            if (!target.isComplete && target.estimatedOrdersToComplete > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                      color: Colors.blueAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ancora ~${target.estimatedOrdersToComplete} ordini per raggiungere €${target.targetAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Congratulazioni se completato
            if (target.isComplete) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text('🎉', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Obiettivo raggiunto! Ottimo lavoro!',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Badge stato obiettivo
class _StatusBadge extends StatelessWidget {
  final bool isComplete;

  const _StatusBadge({required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isComplete
            ? Colors.greenAccent.withOpacity(0.2)
            : Colors.blueAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isComplete ? 'COMPLETATO' : 'IN CORSO',
        style: TextStyle(
          color: isComplete ? Colors.greenAccent : Colors.blueAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Item statistica
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.white38),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}
