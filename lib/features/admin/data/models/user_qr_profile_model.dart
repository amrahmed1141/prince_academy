class UserQrProfile {
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

  const UserQrProfile({
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
  });

  bool get isActive => subscriptionStatus == 'active';

  String get coachLabel {
    final specialty = coachSpecialty?.trim();
    if (specialty != null && specialty.isNotEmpty) {
      return '$coachName · $specialty';
    }
    return coachName;
  }

  factory UserQrProfile.fromJson(Map<String, dynamic> json) {
    return UserQrProfile(
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
