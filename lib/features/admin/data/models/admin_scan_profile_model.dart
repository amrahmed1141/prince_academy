class AdminScanProfile {
  final String userId;
  final String fullName;
  final String? phone;
  final String qrCode;
  final String bookingId;
  final String coachId;
  final String coachName;
  final String? coachPhoto;
  final String? coachSpecialty;
  final List<String> selectedDays;
  final String? selectedTime;
  final double totalPrice;
  final String? paymentMethod;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final String subscriptionStatus;
  final int daysRemaining;
  final int totalSessions;
  final int attendedSessions;
  final int remainingSessions;
  final bool alreadyCheckedInToday;
  final bool isScheduledToday;

  const AdminScanProfile({
    required this.userId,
    required this.fullName,
    this.phone,
    required this.qrCode,
    required this.bookingId,
    required this.coachId,
    required this.coachName,
    this.coachPhoto,
    this.coachSpecialty,
    this.selectedDays = const [],
    this.selectedTime,
    this.totalPrice = 0,
    this.paymentMethod,
    this.subscriptionStart,
    this.subscriptionEnd,
    required this.subscriptionStatus,
    this.daysRemaining = 0,
    this.totalSessions = 0,
    this.attendedSessions = 0,
    this.remainingSessions = 0,
    this.alreadyCheckedInToday = false,
    this.isScheduledToday = false,
  });

  bool get isActive => subscriptionStatus == 'active';

  String get coachLabel {
    final specialty = coachSpecialty?.trim();
    if (specialty != null && specialty.isNotEmpty) {
      return '$coachName · $specialty';
    }
    return coachName;
  }

  factory AdminScanProfile.fromJson(Map<String, dynamic> json) {
    return AdminScanProfile(
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      qrCode: json['qr_code'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      coachId: json['coach_id'] as String? ?? '',
      coachName: json['coach_name'] as String? ?? 'Coach',
      coachPhoto: json['coach_photo'] as String?,
      coachSpecialty: json['coach_specialty'] as String? ??
          json['specialty'] as String? ??
          json['session_type'] as String?,
      selectedDays: _parseStringList(json['selected_days']),
      selectedTime: json['selected_time'] as String?,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String?,
      subscriptionStart: _parseDate(json['subscription_start']),
      subscriptionEnd: _parseDate(json['subscription_end']),
      subscriptionStatus: json['subscription_status'] as String? ?? 'expired',
      daysRemaining: (json['days_remaining'] as num?)?.toInt() ?? 0,
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      attendedSessions: (json['attended_sessions'] as num?)?.toInt() ?? 0,
      remainingSessions: (json['remaining_sessions'] as num?)?.toInt() ?? 0,
      alreadyCheckedInToday:
          json['already_checked_in_today'] as bool? ?? false,
      isScheduledToday: json['is_scheduled_today'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'qr_code': qrCode,
      'booking_id': bookingId,
      'coach_id': coachId,
      'coach_name': coachName,
      'coach_photo': coachPhoto,
      'coach_specialty': coachSpecialty,
      'selected_days': selectedDays,
      'selected_time': selectedTime,
      'total_price': totalPrice,
      'payment_method': paymentMethod,
      'subscription_start': subscriptionStart?.toIso8601String(),
      'subscription_end': subscriptionEnd?.toIso8601String(),
      'subscription_status': subscriptionStatus,
      'days_remaining': daysRemaining,
      'total_sessions': totalSessions,
      'attended_sessions': attendedSessions,
      'remaining_sessions': remainingSessions,
      'already_checked_in_today': alreadyCheckedInToday,
      'is_scheduled_today': isScheduledToday,
    };
  }

  AdminScanProfile copyWith({
    String? userId,
    String? fullName,
    String? phone,
    String? qrCode,
    String? bookingId,
    String? coachId,
    String? coachName,
    String? coachPhoto,
    String? coachSpecialty,
    List<String>? selectedDays,
    String? selectedTime,
    double? totalPrice,
    String? paymentMethod,
    DateTime? subscriptionStart,
    DateTime? subscriptionEnd,
    String? subscriptionStatus,
    int? daysRemaining,
    int? totalSessions,
    int? attendedSessions,
    int? remainingSessions,
    bool? alreadyCheckedInToday,
    bool? isScheduledToday,
  }) {
    return AdminScanProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      qrCode: qrCode ?? this.qrCode,
      bookingId: bookingId ?? this.bookingId,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      coachPhoto: coachPhoto ?? this.coachPhoto,
      coachSpecialty: coachSpecialty ?? this.coachSpecialty,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedTime: selectedTime ?? this.selectedTime,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      subscriptionStart: subscriptionStart ?? this.subscriptionStart,
      subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      totalSessions: totalSessions ?? this.totalSessions,
      attendedSessions: attendedSessions ?? this.attendedSessions,
      remainingSessions: remainingSessions ?? this.remainingSessions,
      alreadyCheckedInToday:
          alreadyCheckedInToday ?? this.alreadyCheckedInToday,
      isScheduledToday: isScheduledToday ?? this.isScheduledToday,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
