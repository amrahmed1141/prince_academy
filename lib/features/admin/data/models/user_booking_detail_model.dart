class UserBookingDetail {
  final String bookingId;
  final String coachId;
  final String coachName;
  final String? coachPhoto;
  final String coachSpecialty;
  final List<String> selectedDays;
  final String selectedTime;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final int totalSessions;
  final int attendedSessions;
  final int remainingSessions;
  final String subscriptionStatus;
  final double totalPrice;

  const UserBookingDetail({
    required this.bookingId,
    required this.coachId,
    required this.coachName,
    this.coachPhoto,
    required this.coachSpecialty,
    required this.selectedDays,
    required this.selectedTime,
    this.subscriptionStart,
    this.subscriptionEnd,
    required this.totalSessions,
    required this.attendedSessions,
    required this.remainingSessions,
    required this.subscriptionStatus,
    required this.totalPrice,
  });

  bool get isActive => subscriptionStatus.toLowerCase() == 'active';

  factory UserBookingDetail.fromJson(Map<String, dynamic> json) {
    return UserBookingDetail(
      bookingId: json['booking_id'] as String? ?? '',
      coachId: json['coach_id'] as String? ?? '',
      coachName: json['coach_name'] as String? ?? 'Coach',
      coachPhoto: json['coach_photo'] as String?,
      coachSpecialty: json['coach_specialty'] as String? ?? '',
      selectedDays: (json['selected_days'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      selectedTime: json['selected_time'] as String? ?? '',
      subscriptionStart: _parseDate(json['subscription_start']),
      subscriptionEnd: _parseDate(json['subscription_end']),
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      attendedSessions: (json['attended_sessions'] as num?)?.toInt() ?? 0,
      remainingSessions: (json['remaining_sessions'] as num?)?.toInt() ?? 0,
      subscriptionStatus: json['subscription_status'] as String? ?? 'active',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
