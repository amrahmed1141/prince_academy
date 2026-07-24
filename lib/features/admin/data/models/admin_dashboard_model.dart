import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';

class AdminDashboardData extends Equatable {
  const AdminDashboardData({
    required this.pendingPaymentsCount,
    required this.pendingPaymentsPreview,
    required this.todayRevenue,
    required this.activeMembersCount,
    required this.todaySessionsCount,
    required this.todaySessionsPreview,
  });

  final int pendingPaymentsCount;
  final List<PendingPaymentModel> pendingPaymentsPreview;
  final double todayRevenue;
  final int activeMembersCount;
  final int todaySessionsCount;
  final List<DashboardTodaySession> todaySessionsPreview;

  @override
  List<Object?> get props => [
        pendingPaymentsCount,
        pendingPaymentsPreview,
        todayRevenue,
        activeMembersCount,
        todaySessionsCount,
        todaySessionsPreview,
      ];
}

class DashboardTodaySession extends Equatable {
  const DashboardTodaySession({
    required this.bookingId,
    required this.userId,
    required this.memberName,
    required this.coachName,
    this.selectedTime,
    this.alreadyCheckedIn = false,
  });

  final String bookingId;
  final String userId;
  final String memberName;
  final String coachName;
  final String? selectedTime;
  final bool alreadyCheckedIn;

  factory DashboardTodaySession.fromJson(Map<String, dynamic> json) {
    return DashboardTodaySession(
      bookingId: json['booking_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      memberName: json['full_name'] as String? ??
          json['user_name'] as String? ??
          json['member_name'] as String? ??
          'Member',
      coachName: json['coach_name'] as String? ?? 'Coach',
      selectedTime: json['selected_time'] as String?,
      alreadyCheckedIn: json['already_checked_in'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        userId,
        memberName,
        coachName,
        selectedTime,
        alreadyCheckedIn,
      ];
}
