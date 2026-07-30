import 'package:prince_academy/features/admin/data/models/admin_dashboard_model.dart';

/// Lifecycle of a coach session relative to [now].
enum SessionLivePhase {
  /// Start time is still in the future.
  upcoming,

  /// Clock minute matches the session start.
  startingNow,

  /// Between start and end (after the starting minute).
  inProgress,

  /// Past end time (start + duration).
  finished,
}

/// Computed live status for a timed coach session.
class SessionLiveStatus {
  const SessionLiveStatus({
    required this.phase,
    this.remaining,
    this.untilStart,
  });

  final SessionLivePhase phase;
  final Duration? remaining;
  final Duration? untilStart;

  bool get isLive =>
      phase == SessionLivePhase.startingNow ||
      phase == SessionLivePhase.inProgress;

  String get label => labelAt(DateTime.now());

  String labelAt(DateTime now) {
    switch (phase) {
      case SessionLivePhase.upcoming:
        final wait = untilStart;
        if (wait == null) return 'Upcoming';
        if (_crossesMidnight(now, wait)) return 'Tomorrow';
        return 'Starts in ${_formatDuration(wait)}';
      case SessionLivePhase.startingNow:
        return 'Starting now';
      case SessionLivePhase.inProgress:
        final left = remaining;
        if (left == null) return 'In progress';
        return 'Remaining ${_formatDuration(left)}';
      case SessionLivePhase.finished:
        return 'Finished';
    }
  }

  /// True when the session's start time falls on a different calendar day.
  static bool _crossesMidnight(DateTime now, Duration untilStart) {
    final sessionStart = now.add(untilStart);
    return sessionStart.day != now.day ||
        sessionStart.month != now.month ||
        sessionStart.year != now.year;
  }

  static String _formatDuration(Duration value) {
    final totalMinutes = value.inMinutes;
    if (totalMinutes <= 0) {
      final seconds = value.inSeconds;
      if (seconds <= 0) return '0 min';
      return '<1 min';
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return hours == 1 ? '1 hour' : '$hours hours';
    return minutes == 1 ? '1 min' : '$minutes min';
  }
}

/// Parses session time slots and picks current / upcoming sessions.
abstract final class SessionLiveStatusHelper {
  static const defaultDurationMinutes = 60;

  /// Resolves status for [session] at [now] (local).
  static SessionLiveStatus resolve(
    DashboardTodaySession session, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final start = startDateTime(session.sessionTime, onDay: current);
    if (start == null) {
      return const SessionLiveStatus(phase: SessionLivePhase.upcoming);
    }

    final durationMinutes = session.durationMinutes > 0
        ? session.durationMinutes
        : defaultDurationMinutes;
    final end = start.add(Duration(minutes: durationMinutes));

    if (current.isBefore(start)) {
      return SessionLiveStatus(
        phase: SessionLivePhase.upcoming,
        untilStart: start.difference(current),
      );
    }

    if (!current.isBefore(end)) {
      return const SessionLiveStatus(phase: SessionLivePhase.finished);
    }

    final sameClockMinute =
        current.hour == start.hour && current.minute == start.minute;
    if (sameClockMinute) {
      return SessionLiveStatus(
        phase: SessionLivePhase.startingNow,
        remaining: end.difference(current),
      );
    }

    return SessionLiveStatus(
      phase: SessionLivePhase.inProgress,
      remaining: end.difference(current),
    );
  }

  /// Prefers an in-progress / starting session; otherwise the next upcoming.
  /// Returns null when every timed session has finished (or list is empty).
  static DashboardTodaySession? pickCurrentOrUpcoming(
    List<DashboardTodaySession> sessions, {
    DateTime? now,
  }) {
    final visible = currentAndUpcoming(sessions, now: now);
    return visible.isEmpty ? null : visible.first;
  }

  /// Live sessions first (by start), then upcoming (by start). Finished excluded.
  static List<DashboardTodaySession> currentAndUpcoming(
    List<DashboardTodaySession> sessions, {
    DateTime? now,
  }) {
    if (sessions.isEmpty) return const [];
    final current = now ?? DateTime.now();

    final timed = <({DashboardTodaySession session, DateTime start})>[];
    final untimed = <DashboardTodaySession>[];

    for (final session in sessions) {
      final start = startDateTime(session.sessionTime, onDay: current);
      if (start == null) {
        untimed.add(session);
        continue;
      }
      timed.add((session: session, start: start));
    }

    timed.sort((a, b) => a.start.compareTo(b.start));

    final live = <DashboardTodaySession>[];
    final upcoming = <DashboardTodaySession>[];

    for (final entry in timed) {
      final status = resolve(entry.session, now: current);
      if (status.isLive) {
        live.add(entry.session);
      } else if (status.phase == SessionLivePhase.upcoming) {
        upcoming.add(entry.session);
      }
    }

    // Untimed slots stay at the end so they still appear in the carousel.
    return [...live, ...upcoming, ...untimed];
  }

  /// Parses display times like `5:00 PM`, `17:00`, `5:00pm`.
  static DateTime? startDateTime(String? raw, {DateTime? onDay}) {
    final time = parseTimeOfDay(raw);
    if (time == null) return null;
    final day = onDay ?? DateTime.now();
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  static ({int hour, int minute})? parseTimeOfDay(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty || value.toLowerCase() == 'time tbd') return null;

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(value.replaceAll(RegExp(r'\s+'), ' '));
    if (match == null) return null;

    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) return null;
    if (minute < 0 || minute > 59 || hour < 0 || hour > 23) return null;

    final meridiem = match.group(3)?.toUpperCase();
    if (meridiem != null) {
      if (hour < 1 || hour > 12) return null;
      if (meridiem == 'AM') {
        if (hour == 12) hour = 0;
      } else {
        if (hour != 12) hour += 12;
      }
    }

    return (hour: hour, minute: minute);
  }
}
