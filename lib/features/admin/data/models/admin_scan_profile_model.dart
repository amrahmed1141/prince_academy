import 'package:prince_academy/core/helpers/session_schedule_helper.dart';

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
  final String? branchId;
  final String? branchName;
  final List<String> selectedDays;
  final String? selectedTime;
  final double totalPrice;
  final String? paymentMethod;
  final String? paymentStatus;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final String subscriptionStatus;
  final int daysRemaining;
  final int totalSessions;
  final int attendedSessions;
  final int remainingSessions;
  final bool alreadyCheckedInToday;
  final bool isScheduledToday;
  final DateTime? createdAt;
  final DateTime? paymentDeadline;
  final String? paymentReference;
  final String? paymentScreenshotUrl;

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
    this.branchId,
    this.branchName,
    this.selectedDays = const [],
    this.selectedTime,
    this.totalPrice = 0,
    this.paymentMethod,
    this.paymentStatus,
    this.subscriptionStart,
    this.subscriptionEnd,
    required this.subscriptionStatus,
    this.daysRemaining = 0,
    this.totalSessions = 0,
    this.attendedSessions = 0,
    this.remainingSessions = 0,
    this.alreadyCheckedInToday = false,
    this.isScheduledToday = false,
    this.createdAt,
    this.paymentDeadline,
    this.paymentReference,
    this.paymentScreenshotUrl,
  });

  bool get needsPaymentVerification {
    final pay = paymentStatus?.toLowerCase();
    if (pay == 'pending_payment' ||
        pay == 'awaiting_verification' ||
        pay == 'pending') {
      return true;
    }
    final sub = subscriptionStatus.toLowerCase();
    if (sub == 'pending_payment' || sub == 'pending') {
      final verified = pay == 'verified' || pay == 'paid' || pay == 'active';
      return !verified;
    }
    return false;
  }

  bool get _isPastSubscriptionEnd {
    if (subscriptionEnd == null) return false;
    final today = SessionScheduleHelper.dateOnly(DateTime.now());
    final end = SessionScheduleHelper.dateOnly(subscriptionEnd!);
    return today.isAfter(end);
  }

  bool get _isPaymentVerified {
    final pay = paymentStatus?.toLowerCase();
    return pay == 'verified' || pay == 'paid' || pay == 'active';
  }

  bool get isActive {
    if (needsPaymentVerification) return false;
    if (_isPastSubscriptionEnd) return false;
    final sub = subscriptionStatus.toLowerCase();
    if (sub == 'expired' || sub == 'cancelled' || sub == 'rejected') {
      return false;
    }
    if (_isPaymentVerified) return true;
    return sub == 'active' || sub == 'approved';
  }

  bool get hasSessionToday =>
      isScheduledToday ||
      SessionScheduleHelper.isSessionDayOnDate(
        selectedDays: selectedDays,
        subscriptionStart: subscriptionStart,
        subscriptionEnd: subscriptionEnd,
      );

  bool get canMarkAttendanceToday => isActive && hasSessionToday;

  AdminScanProfile asPaymentVerified() {
    return copyWith(
      paymentStatus: 'verified',
      subscriptionStatus: 'active',
      isScheduledToday: hasSessionToday,
    );
  }

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
      branchId: json['branch_id'] as String?,
      branchName: json['branch_name'] as String?,
      selectedDays: _parseStringList(json['selected_days']),
      selectedTime: json['selected_time'] as String?,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String?,
      paymentStatus: json['payment_status'] as String?,
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
      createdAt: _parseDate(json['created_at']),
      paymentDeadline: _parseDate(json['payment_deadline']),
      paymentReference: json['payment_reference'] as String?,
      paymentScreenshotUrl: json['payment_screenshot_url'] as String?,
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
      'branch_id': branchId,
      'branch_name': branchName,
      'selected_days': selectedDays,
      'selected_time': selectedTime,
      'total_price': totalPrice,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
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
    String? branchId,
    String? branchName,
    List<String>? selectedDays,
    String? selectedTime,
    double? totalPrice,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? subscriptionStart,
    DateTime? subscriptionEnd,
    String? subscriptionStatus,
    int? daysRemaining,
    int? totalSessions,
    int? attendedSessions,
    int? remainingSessions,
    bool? alreadyCheckedInToday,
    bool? isScheduledToday,
    DateTime? createdAt,
    DateTime? paymentDeadline,
    String? paymentReference,
    String? paymentScreenshotUrl,
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
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedTime: selectedTime ?? this.selectedTime,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
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
      createdAt: createdAt ?? this.createdAt,
      paymentDeadline: paymentDeadline ?? this.paymentDeadline,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentScreenshotUrl:
          paymentScreenshotUrl ?? this.paymentScreenshotUrl,
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
