class TodayBooking {
  final String bookingId;
  final String userId;
  final String coachId;
  final String coachName;
  final String? selectedTime;
  final DateTime? subscriptionEnd;
  final bool alreadyCheckedIn;

  const TodayBooking({
    required this.bookingId,
    required this.userId,
    required this.coachId,
    required this.coachName,
    this.selectedTime,
    this.subscriptionEnd,
    this.alreadyCheckedIn = false,
  });

  factory TodayBooking.fromJson(Map<String, dynamic> json) {
    return TodayBooking(
      bookingId: json['booking_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      coachId: json['coach_id'] as String? ?? '',
      coachName: json['coach_name'] as String? ?? 'Coach',
      selectedTime: json['selected_time'] as String?,
      subscriptionEnd: _parseDate(json['subscription_end']),
      alreadyCheckedIn: json['already_checked_in'] as bool? ?? false,
    );
  }

  TodayBooking copyWith({
    String? bookingId,
    String? userId,
    String? coachId,
    String? coachName,
    String? selectedTime,
    DateTime? subscriptionEnd,
    bool? alreadyCheckedIn,
  }) {
    return TodayBooking(
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      selectedTime: selectedTime ?? this.selectedTime,
      subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
      alreadyCheckedIn: alreadyCheckedIn ?? this.alreadyCheckedIn,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
