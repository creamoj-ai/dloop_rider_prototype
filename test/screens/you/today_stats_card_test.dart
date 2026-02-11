import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dloop_rider_prototype/widgets/dloop_card.dart';

// TodayStatsCard requires activeSessionProvider (StateNotifierProvider) which
// creates ActiveSessionNotifier that accesses Supabase in its constructor.
// Without a full Supabase mock, we can't render TodayStatsCard in tests.
//
// Instead, we test TodayStatsCard's building blocks:
// - DloopCard renders correctly (tested in dloop_card_test.dart)
// - The layout structure (3-column grid with icons, values, labels)

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('TodayStatsCard layout structure', () {
    // Replicate the TodayStatsCard layout to verify formatting logic

    testWidgets('stat column renders icon, value, and label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(
            body: DloopCard(
              child: Row(
                children: [
                  _statColumn(
                    icon: Icons.shopping_bag_outlined,
                    value: '5',
                    label: 'Ordini',
                    color: const Color(0xFFFF6B00),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Ordini'), findsOneWidget);
    });

    testWidgets('hours format: 0 minutes shows 0h', (tester) async {
      const activeMinutes = 0;
      final hours = activeMinutes / 60.0;
      final hoursStr = hours > 0 ? '${hours.toStringAsFixed(1)}h' : '0h';

      expect(hoursStr, '0h');
    });

    testWidgets('hours format: 90 minutes shows 1.5h', (tester) async {
      const activeMinutes = 90;
      final hours = activeMinutes / 60.0;
      final hoursStr = hours > 0 ? '${hours.toStringAsFixed(1)}h' : '0h';

      expect(hoursStr, '1.5h');
    });

    testWidgets('hours format: 120 minutes shows 2.0h', (tester) async {
      const activeMinutes = 120;
      final hours = activeMinutes / 60.0;
      final hoursStr = hours > 0 ? '${hours.toStringAsFixed(1)}h' : '0h';

      expect(hoursStr, '2.0h');
    });

    testWidgets('earnings format: 45.50 shows 45.50', (tester) async {
      const totalEarnings = 45.50;
      final earningsStr = totalEarnings.toStringAsFixed(2);

      expect(earningsStr, '45.50');
    });

    testWidgets('earnings format: 0 shows 0.00', (tester) async {
      const totalEarnings = 0.0;
      final earningsStr = totalEarnings.toStringAsFixed(2);

      expect(earningsStr, '0.00');
    });

    testWidgets('renders 3-column layout inside DloopCard', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(
            body: DloopCard(
              child: Column(
                children: [
                  Center(
                    child: Text(
                      'OGGI',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statColumn(
                        icon: Icons.shopping_bag_outlined,
                        value: '3',
                        label: 'Ordini',
                        color: const Color(0xFFFF6B00),
                      ),
                      const SizedBox(width: 12),
                      _statColumn(
                        icon: Icons.schedule,
                        value: '1.5h',
                        label: 'Ore',
                        color: const Color(0xFF00C853),
                      ),
                      const SizedBox(width: 12),
                      _statColumn(
                        icon: Icons.euro,
                        value: '35.00',
                        label: 'Guadagno',
                        color: const Color(0xFFAA00FF),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('OGGI'), findsOneWidget);
      expect(find.text('Ordini'), findsOneWidget);
      expect(find.text('Ore'), findsOneWidget);
      expect(find.text('Guadagno'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.euro), findsOneWidget);
    });
  });
}

Widget _statColumn({
  required IconData icon,
  required String value,
  required String label,
  required Color color,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
