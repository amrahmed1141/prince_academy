import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_summary.dart';
import 'package:prince_academy/features/sessions/presentation/widgets/session_card.dart';

class UpcomingSessionCard extends StatelessWidget {
  final BookingHistoryModel booking;
  final TodaySessionInfo? todaySession;
  final VoidCallback? onTap;

  const UpcomingSessionCard({
    super.key,
    required this.booking,
    this.todaySession,
    this.onTap,
  });

  factory UpcomingSessionCard.fromSession(
    Session session, {
    BookingHistoryModel? booking,
    TodaySessionInfo? todaySession,
    VoidCallback? onTap,
  }) {
    return UpcomingSessionCard(
      booking: booking ?? SessionCard.bookingFromSession(session),
      todaySession: todaySession,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            'Upcoming',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        SessionCard(
          booking: booking,
          todaySession: todaySession,
          onTap: onTap,
        ),
      ],
    );
  }
}
