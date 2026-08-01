import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/session_schedule_helper.dart';
import 'package:prince_academy/features/admin/data/models/session_detail_model.dart';
import 'package:table_calendar/table_calendar.dart';

/// Month calendar for picking sessions to freeze.
///
/// - Red ring: missed
/// - Green ring: upcoming / today
/// - Filled primary: selected for freeze
class FreezeSessionSelector extends StatefulWidget {
  const FreezeSessionSelector({
    super.key,
    required this.sessions,
    required this.selectedKeys,
    required this.onToggle,
  });

  final List<SessionDetail> sessions;
  final Set<String> selectedKeys;
  final ValueChanged<SessionDetail> onToggle;

  @override
  State<FreezeSessionSelector> createState() => _FreezeSessionSelectorState();
}

class _FreezeSessionSelectorState extends State<FreezeSessionSelector> {
  static const _missedRed = Color(0xFFC62828);
  static const _upcomingGreen = Color(0xFF2E7D32);

  late DateTime _focusedDay;
  late Map<DateTime, SessionDetail> _byDate;

  @override
  void initState() {
    super.initState();
    _rebuildIndex();
    _focusedDay = _initialFocusedDay();
  }

  @override
  void didUpdateWidget(covariant FreezeSessionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessions != widget.sessions) {
      _rebuildIndex();
      final focused = SessionScheduleHelper.dateOnly(_focusedDay);
      if (!_inRange(focused)) {
        _focusedDay = _initialFocusedDay();
      }
    }
  }

  void _rebuildIndex() {
    _byDate = {
      for (final s in widget.sessions)
        SessionScheduleHelper.dateOnly(s.sessionDate): s,
    };
  }

  DateTime _initialFocusedDay() {
    if (widget.sessions.isEmpty) {
      return SessionScheduleHelper.dateOnly(DateTime.now());
    }
    final sorted = widget.sessions
        .map((s) => SessionScheduleHelper.dateOnly(s.sessionDate))
        .toList()
      ..sort();
    final today = SessionScheduleHelper.dateOnly(DateTime.now());
    for (final d in sorted) {
      if (!d.isBefore(today)) return d;
    }
    return sorted.last;
  }

  DateTime get _firstDay {
    if (_byDate.isEmpty) {
      return SessionScheduleHelper.dateOnly(DateTime.now())
          .subtract(const Duration(days: 30));
    }
    final dates = _byDate.keys.toList()..sort();
    return dates.first.subtract(const Duration(days: 7));
  }

  DateTime get _lastDay {
    if (_byDate.isEmpty) {
      return SessionScheduleHelper.dateOnly(DateTime.now())
          .add(const Duration(days: 60));
    }
    final dates = _byDate.keys.toList()..sort();
    return dates.last.add(const Duration(days: 7));
  }

  bool _inRange(DateTime day) {
    final d = SessionScheduleHelper.dateOnly(day);
    return !d.isBefore(_firstDay) && !d.isAfter(_lastDay);
  }

  String _keyFor(DateTime day) {
    final d = SessionScheduleHelper.dateOnly(day);
    return '${d.year}-${d.month}-${d.day}';
  }

  Color? _ringColor(SessionDetail session) {
    final status = session.status.toLowerCase();
    if (status == 'missed') return _missedRed;
    if (status == 'upcoming' || status == 'today') return _upcomingGreen;
    return EColorConstants.authPlaceholderGray;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: EColorConstants.authCardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.only(bottom: 8),
          child: TableCalendar<SessionDetail>(
            firstDay: _firstDay,
            lastDay: _lastDay,
            focusedDay: _focusedDay.isBefore(_firstDay)
                ? _firstDay
                : (_focusedDay.isAfter(_lastDay) ? _lastDay : _focusedDay),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            availableGestures: AvailableGestures.horizontalSwipe,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                fontSize: 15,
                color: EColorConstants.authTextDarkBrown,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: EColorConstants.authTextDarkBrown,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: EColorConstants.authTextDarkBrown,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: EColorConstants.authPlaceholderGray,
              ),
              weekendStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: EColorConstants.authPlaceholderGray,
              ),
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              isTodayHighlighted: false,
            ),
            selectedDayPredicate: (day) =>
                widget.selectedKeys.contains(_keyFor(day)),
            onPageChanged: (focused) {
              setState(() => _focusedDay = focused);
            },
            onDaySelected: (selected, focused) {
              setState(() => _focusedDay = focused);
              final session =
                  _byDate[SessionScheduleHelper.dateOnly(selected)];
              if (session != null) {
                widget.onToggle(session);
              }
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focused) =>
                  _DayCell(
                    day: day,
                    session: _byDate[SessionScheduleHelper.dateOnly(day)],
                    selected: widget.selectedKeys.contains(_keyFor(day)),
                    ringColorFor: _ringColor,
                  ),
              todayBuilder: (context, day, focused) =>
                  _DayCell(
                    day: day,
                    session: _byDate[SessionScheduleHelper.dateOnly(day)],
                    selected: widget.selectedKeys.contains(_keyFor(day)),
                    ringColorFor: _ringColor,
                    isToday: true,
                  ),
              selectedBuilder: (context, day, focused) =>
                  _DayCell(
                    day: day,
                    session: _byDate[SessionScheduleHelper.dateOnly(day)],
                    selected: true,
                    ringColorFor: _ringColor,
                  ),
              disabledBuilder: (context, day, focused) =>
                  _DayCell(
                    day: day,
                    session: null,
                    selected: false,
                    ringColorFor: _ringColor,
                    disabled: true,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _FreezeCalendarLegend(),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.session,
    required this.selected,
    required this.ringColorFor,
    this.isToday = false,
    this.disabled = false,
  });

  final DateTime day;
  final SessionDetail? session;
  final bool selected;
  final Color? Function(SessionDetail session) ringColorFor;
  final bool isToday;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final hasSession = session != null;
    final ring = hasSession ? ringColorFor(session!) : null;

    BoxDecoration? decoration;
    Color textColor = disabled
        ? EColorConstants.authPlaceholderGray.withOpacity(0.35)
        : EColorConstants.authTextDarkBrown;

    if (selected && hasSession) {
      decoration = const BoxDecoration(
        color: EColorConstants.primaryColor,
        shape: BoxShape.circle,
      );
      textColor = Colors.white;
    } else if (hasSession && ring != null) {
      decoration = BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
      );
      textColor = ring;
    } else if (isToday) {
      decoration = BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: EColorConstants.primaryColor.withOpacity(0.45),
          width: 1.5,
        ),
      );
    }

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: decoration,
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: hasSession ? FontWeight.w700 : FontWeight.w500,
            fontFamily: 'Poppins',
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _FreezeCalendarLegend extends StatelessWidget {
  const _FreezeCalendarLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _LegendDot(color: Color(0xFFC62828), label: 'Missed'),
        SizedBox(width: 16),
        _LegendDot(color: Color(0xFF2E7D32), label: 'Upcoming'),
        SizedBox(width: 16),
        _LegendDot(
          color: EColorConstants.primaryColor,
          label: 'Selected',
          filled: true,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.filled = false,
  });

  final Color color;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'Poppins',
            color: EColorConstants.authPlaceholderGray,
          ),
        ),
      ],
    );
  }
}
