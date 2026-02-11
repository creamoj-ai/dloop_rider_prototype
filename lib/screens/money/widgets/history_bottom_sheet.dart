import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';
import '../../../models/earning.dart';
import '../../../providers/transactions_provider.dart';

class HistoryBottomSheet extends ConsumerStatefulWidget {
  const HistoryBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HistoryBottomSheet(),
    );
  }

  @override
  ConsumerState<HistoryBottomSheet> createState() => _HistoryBottomSheetState();
}

class _HistoryBottomSheetState extends ConsumerState<HistoryBottomSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isCalendarExpanded = true;
  bool _isRangeMode = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
  }

  /// Group all transactions by date key, filtered to selection
  List<Earning> get _activitiesForSelection {
    final allTxs = ref.read(allTransactionsProvider);

    if (_isRangeMode && _startDate != null && _endDate != null) {
      final startDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final endDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      return allTxs.where((t) =>
        t.dateTime.isAfter(startDay.subtract(const Duration(seconds: 1))) &&
        t.dateTime.isBefore(endDay.add(const Duration(seconds: 1)))
      ).toList();
    } else if (_startDate != null) {
      final dayStart = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      return allTxs.where((t) =>
        t.dateTime.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
        t.dateTime.isBefore(dayEnd)
      ).toList();
    }

    return [];
  }

  /// Get set of date keys that have transactions (for calendar dots)
  Set<String> get _datesWithData {
    final allTxs = ref.read(allTransactionsProvider);
    return allTxs.map((t) => _dateKey(t.dateTime)).toSet();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  double get _totalForSelection {
    return _activitiesForSelection.fold(0, (sum, a) => sum + a.amount);
  }

  int get _ordersForSelection {
    return _activitiesForSelection.where((a) => a.type == EarningType.delivery).length;
  }

  int get _daysInSelection {
    if (!_isRangeMode || _endDate == null || _startDate == null) return 1;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  void _onDayTap(DateTime date) {
    setState(() {
      if (_isRangeMode) {
        if (_startDate == null || (_startDate != null && _endDate != null)) {
          _startDate = date;
          _endDate = null;
        } else {
          if (date.isBefore(_startDate!)) {
            _endDate = _startDate;
            _startDate = date;
          } else {
            _endDate = date;
          }
          _isCalendarExpanded = false;
        }
      } else {
        _startDate = date;
        _endDate = null;
        _isCalendarExpanded = false;
      }
    });
  }

  bool _isInRange(DateTime date) {
    if (_startDate == null) return false;
    if (_endDate == null) {
      return date.year == _startDate!.year && date.month == _startDate!.month && date.day == _startDate!.day;
    }
    return !date.isBefore(_startDate!) && !date.isAfter(_endDate!);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Watch to trigger rebuilds on new transactions
    ref.watch(allTransactionsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(cs),
          _buildHeader(cs),
          _buildModeToggle(cs),
          if (_isCalendarExpanded) ...[
            _buildMonthSelector(cs),
            _buildWeekDays(cs),
            _buildDaysGrid(cs),
          ],
          _buildSelectionSummary(cs),
          Expanded(child: _buildActivitiesList(cs)),
          _buildExportButton(cs),
        ],
      ),
    );
  }

  Widget _buildHandle(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.history, color: AppColors.routeBlue, size: 20),
          const SizedBox(width: 8),
          Text('Storico', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.routeBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month, size: 14, color: AppColors.routeBlue),
                  const SizedBox(width: 4),
                  Icon(
                    _isCalendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.routeBlue,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.close, color: cs.onSurfaceVariant, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _modeChip('Giorno', !_isRangeMode, () => setState(() {
            _isRangeMode = false;
            _endDate = null;
            _isCalendarExpanded = true;
          }), cs),
          const SizedBox(width: 8),
          _modeChip('Range', _isRangeMode, () => setState(() {
            _isRangeMode = true;
            _startDate = null;
            _endDate = null;
            _isCalendarExpanded = true;
          }), cs),
        ],
      ),
    );
  }

  Widget _modeChip(String label, bool selected, VoidCallback onTap, ColorScheme cs) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.routeBlue : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector(ColorScheme cs) {
    final months = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => setState(() {
              if (_selectedMonth == 1) { _selectedMonth = 12; _selectedYear--; }
              else { _selectedMonth--; }
            }),
            child: Icon(Icons.chevron_left, color: cs.onSurfaceVariant, size: 22),
          ),
          Text(
            '${months[_selectedMonth - 1]} $_selectedYear',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
          ),
          GestureDetector(
            onTap: () => setState(() {
              if (_selectedMonth == 12) { _selectedMonth = 1; _selectedYear++; }
              else { _selectedMonth++; }
            }),
            child: Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays(ColorScheme cs) {
    final days = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: days.map((d) => Expanded(
          child: Center(child: Text(d, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant))),
        )).toList(),
      ),
    );
  }

  Widget _buildDaysGrid(ColorScheme cs) {
    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    final lastDay = DateTime(_selectedYear, _selectedMonth + 1, 0);
    final startWeekday = (firstDay.weekday - 1) % 7;
    final datesWithData = _datesWithData;

    List<Widget> dayWidgets = [];

    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_selectedYear, _selectedMonth, day);
      final inRange = _isInRange(date);
      final isStart = _startDate != null && date.year == _startDate!.year && date.month == _startDate!.month && date.day == _startDate!.day;
      final isEnd = _endDate != null && date.year == _endDate!.year && date.month == _endDate!.month && date.day == _endDate!.day;
      final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;
      final hasData = datesWithData.contains(_dateKey(date));

      dayWidgets.add(
        GestureDetector(
          onTap: () => _onDayTap(date),
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: inRange ? AppColors.routeBlue.withValues(alpha: isStart || isEnd ? 1 : 0.3) : (isToday ? AppColors.routeBlue.withValues(alpha: 0.1) : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: (isStart || isEnd || isToday) ? FontWeight.w700 : FontWeight.w500,
                    color: (isStart || isEnd) ? Colors.white : cs.onSurface,
                  ),
                ),
                if (hasData)
                  Container(
                    margin: const EdgeInsets.only(top: 1),
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: (isStart || isEnd) ? Colors.white : AppColors.earningsGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 7,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.3,
        children: dayWidgets,
      ),
    );
  }

  Widget _buildSelectionSummary(ColorScheme cs) {
    final weekdays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    final months = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];

    String dateLabel;
    if (_isRangeMode && _startDate != null && _endDate != null) {
      dateLabel = '${_startDate!.day} ${months[_startDate!.month - 1]} - ${_endDate!.day} ${months[_endDate!.month - 1]}';
    } else if (_startDate != null) {
      dateLabel = '${weekdays[_startDate!.weekday - 1]} ${_startDate!.day} ${months[_startDate!.month - 1]}';
    } else {
      dateLabel = 'Seleziona data';
    }

    return GestureDetector(
      onTap: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: AppColors.routeBlue),
            const SizedBox(width: 8),
            Text(dateLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
            if (_isRangeMode && _daysInSelection > 1) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.routeBlue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text('$_daysInSelection gg', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.routeBlue)),
              ),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(6)),
              child: Text('$_ordersForSelection', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface)),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: AppColors.earningsGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Text('\u20AC${_totalForSelection.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.earningsGreen)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesList(ColorScheme cs) {
    final activities = _activitiesForSelection;

    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 36, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 6),
            Text('Nessuna attivita', style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: activities.length,
      itemBuilder: (context, index) => _buildActivityTile(activities[index], cs),
    );
  }

  Widget _buildActivityTile(Earning tx, ColorScheme cs) {
    final color = tx.type == EarningType.delivery ? AppColors.routeBlue
        : tx.type == EarningType.network ? AppColors.bonusPurple
        : AppColors.turboOrange;
    final icon = tx.type == EarningType.delivery ? Icons.delivery_dining
        : tx.type == EarningType.network ? Icons.people
        : Icons.storefront;
    final time = '${tx.dateTime.hour.toString().padLeft(2, '0')}:${tx.dateTime.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text(time, style: GoogleFonts.inter(fontSize: 10, color: cs.onSurfaceVariant))),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(5)),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  tx.type == EarningType.delivery ? 'Consegna'
                      : tx.type == EarningType.network ? 'Network'
                      : 'Market',
                  style: GoogleFonts.inter(fontSize: 9, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text('\u20AC${tx.amount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.earningsGreen)),
        ],
      ),
    );
  }

  Widget _buildExportButton(ColorScheme cs) {
    final months = ['Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno', 'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'];
    String label = _isRangeMode && _startDate != null && _endDate != null
        ? 'Esporta ${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}'
        : 'Esporta ${months[_selectedMonth - 1]} $_selectedYear';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export PDF in arrivo...'), backgroundColor: AppColors.routeBlue),
              );
            },
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.routeBlue,
              side: BorderSide(color: AppColors.routeBlue.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }
}
