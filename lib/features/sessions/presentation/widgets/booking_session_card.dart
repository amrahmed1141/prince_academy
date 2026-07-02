import 'package:flutter/material.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_summary.dart';
import 'package:prince_academy/features/sessions/presentation/widgets/session_card.dart';

class BookingSessionCard extends StatelessWidget {
  final BookingHistoryModel booking;
  final VoidCallback onTap;
  final BookingDisplayStatus displayStatus;
  final TodaySessionInfo? todaySession;

  const BookingSessionCard({
    super.key,
    required this.booking,
    required this.onTap,
    required this.displayStatus,
    this.todaySession,
  });

  @override
  Widget build(BuildContext context) {
    return SessionCard(
      booking: booking,
      todaySession: todaySession,
      onTap: onTap,
    );
  }
}
