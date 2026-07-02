import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_calculator.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_summary.dart';
import 'package:prince_academy/features/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:prince_academy/features/sessions/presentation/widgets/session_card.dart';

class RecentActivity extends StatelessWidget {
  final List<Session> allSessions;
  final List<BookingHistoryModel> bookings;
  final void Function(BookingHistoryModel booking)? onBookingTap;

  const RecentActivity({
    super.key,
    required this.allSessions,
    this.bookings = const [],
    this.onBookingTap,
  });

  List<_RecentBookingActivity> _buildRecentActivities() {
    final now = DateTime.now();
    final weekStart = SessionsBloc.startOfWeek(now);
    final weekEnd = weekStart.add(const Duration(days: 6));

    final completedThisWeek = allSessions.where((s) {
      if (!WeeklyProgressCalculator.isSessionAttended(s)) return false;
      final d = SessionsBloc.dateOnly(s.sessionDate);
      return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
    }).toList();

    final bookingIds = completedThisWeek.map((s) => s.bookingId).toSet();
    final activeBookings =
        bookings.where((b) => bookingIds.contains(b.bookingId)).toList()
          ..sort((a, b) {
            final aLatest = _latestSessionDate(completedThisWeek, a.bookingId);
            final bLatest = _latestSessionDate(completedThisWeek, b.bookingId);
            return bLatest.compareTo(aLatest);
          });

    return activeBookings.map((booking) {
      final todaySession = WeeklyProgressCalculator.todaySessionForBooking(
        booking,
        allSessions,
      );
      return _RecentBookingActivity(
        booking: booking,
        todaySession: todaySession,
      );
    }).toList();
  }

  DateTime _latestSessionDate(List<Session> sessions, String bookingId) {
    final dates = sessions
        .where((s) => s.bookingId == bookingId)
        .map((s) => s.sessionDate)
        .toList();
    if (dates.isEmpty) return DateTime(1970);
    dates.sort((a, b) => b.compareTo(a));
    return dates.first;
  }

  @override
  Widget build(BuildContext context) {
    final activities = _buildRecentActivities();

    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        SizedBox(
          height: 340,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return SessionCard(
                booking: activity.booking,
                todaySession: activity.todaySession,
                onTap: onBookingTap == null
                    ? null
                    : () => onBookingTap!(activity.booking),
                compact: true,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentBookingActivity {
  final BookingHistoryModel booking;
  final TodaySessionInfo? todaySession;

  const _RecentBookingActivity({
    required this.booking,
    this.todaySession,
  });
}
