import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/tokens.dart';

class HistoryBottomSheet extends StatefulWidget {
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
  State<HistoryBottomSheet> createState() => _HistoryBottomSheetState();
}

class _HistoryBottomSheetState extends State<HistoryBottomSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isCalendarExpanded = true;
  bool _isRangeMode = false;

  // Mock data per demo
  final Map<String, List<_DayActivity>> _mockData = {
    '2026-02-05': [
      _DayActivity('09:32', 'Pizzeria Mario', 'Via Roma 15', 4.50, 'earn'),
      _DayActivity('10:15', 'Sushi Zen', 'C.so Italia 8', 5.80, 'earn'),
      _DayActivity('10:58', "McDonald's", 'P.za Duomo 1', 3.90, 'earn'),
      _DayActivity('12:30', 'Comm. Network', 'Marco R.', 2.50, 'network'),
      _DayActivity('14:20', 'Burger King', 'Via Padova 22', 4.20, 'earn'),
      _DayActivity('15:45', 'Market Sale', 'Energy Box', 15.00, 'market'),
      _DayActivity('17:10', 'Poke House', 'Via Torino 8', 5.50, 'earn'),
    ],
    '2026-02-04': [
      _DayActivity('10:00', 'KFC', 'C.so Buenos Aires', 4.80, 'earn'),
      _DayActivity('11:30', 'Pizza Hut', 'Via Montenapoleone', 5.20, 'earn'),
      _DayActivity('13:00', 'Comm. Network', 'Anna V.', 3.00, 'network'),
      _DayActivity('15:00', 'Market Sale', 'Protein Bar', 18.00, 'market'),
    ],
    '2026-02-03': [
      _DayActivity('09:00', 'Starbucks', 'P.za Cordusio', 3.50, 'earn'),
      _DayActivity('10:30', 'Domino\'s', 'Via Dante', 4.90, 'earn'),
      _DayActivity('12:00', 'Five Guys', 'C.so Vittorio Emanuele', 6.20, 'earn'),
    ],
    '2026-02-02': [
      _DayActivity('11:00', 'Roadhouse', 'Via Larga', 5.00, 'earn'),
      _DayActivity('14:00', 'Old Wild West', 'C.so Como', 4.50, 'earn'),
    ],
    '2026-02-01': [
      _DayActivity('09:30', 'Eataly', 'P.za XXV Aprile', 6.80, 'earn'),
      _DayActivity('12:00', 'Comm. Network', 'Luigi B.', 4.00, 'network'),
    ],
  };

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
  }

  List<_DayActivity> get _activitiesForSelection {
    List<_DayActivity> all = [];

    if (_isRangeMode && _startDate != null && _endDate != null) {
      // Range mode
      for (var date = _startDate!; !date.isAfter(_endDate!); date = date.add(const Duration(days: 1))) {
        final key = _dateKey(date);
        all.addAll(_mockData[key] ?? []);
      }
    } else if (_startDate != null) {
      // Single day mode
      final key = _dateKey(_startDate!);
      all = _mockData[key] ?? [];
    }

    return all;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  double get _totalForSelection {
    return _activitiesForSelection.fold(0, (sum, a) => sum + a.amount);
  }

  int get _ordersForSelection {
    return _activitiesForSelection.where((a) => a.type == 'earn').length;
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
          _isCalendarExpanded = false; // Chiudi dopo selezione range
        }
      } else {
        _startDate = date;
        _endDate = null;
        _isCalendarExpanded = false; // Chiudi dopo selezione singola
      }
    });
  }

  bool _isInRange(DateTime date) {
    if (_startDate == null) return false;
    if (_endDate == null) return date == _startDate;
    return !date.isBefore(_startDate!) && !date.isAfter(_endDate!);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
          Icon(Icons.history, color: AppColors.routeBlue, size: 20),
          const SizedBox(width: 8),
          Text('Storico', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const Spacer(),
          // Toggle calendario
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
                  Icon(Icons.calendar_month, size: 14, color: AppColors.routeBlue),
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
      final hasData = _mockData.containsKey(_dateKey(date));

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
            Icon(Icons.calendar_today, size: 14, color: AppColors.routeBlue),
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
              child: Text('📦 $_ordersForSelection', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface)),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: AppColors.earningsGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Text('€${_totalForSelection.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.earningsGreen)),
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
            Text('Nessuna attività', style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
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

  Widget _buildActivityTile(_DayActivity a, ColorScheme cs) {
    final color = a.type == 'earn' ? AppColors.routeBlue : a.type == 'network' ? AppColors.bonusPurple : AppColors.turboOrange;
    final icon = a.type == 'earn' ? Icons.delivery_dining : a.type == 'network' ? Icons.people : Icons.storefront;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text(a.time, style: GoogleFonts.inter(fontSize: 10, color: cs.onSurfaceVariant))),
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
                Text(a.title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(a.subtitle, style: GoogleFonts.inter(fontSize: 9, color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text('€${a.amount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.earningsGreen)),
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
                SnackBar(content: Text('Export PDF in arrivo...'), backgroundColor: AppColors.routeBlue),
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

class _DayActivity {
  final String time;
  final String title;
  final String subtitle;
  final double amount;
  final String type;
  _DayActivity(this.time, this.title, this.subtitle, this.amount, this.type);
}
