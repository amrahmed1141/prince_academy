class PendingPaymentModel {
  final String bookingId;
  final String userId;
  final String userName;
  final String? userPhone;
  final String coachName;
  final String? coachPhoto;
  final String? coachSpecialty;
  final String branchName;
  final List<String> selectedDays;
  final String selectedTime;
  final double totalPrice;
  final String paymentMethod;
  final String? paymentReference;
  final String? paymentScreenshotUrl;
  final DateTime createdAt;
  final DateTime? paymentDeadline;

  const PendingPaymentModel({
    required this.bookingId,
    required this.userId,
    required this.userName,
    this.userPhone,
    required this.coachName,
    this.coachPhoto,
    this.coachSpecialty,
    this.branchName = '',
    this.selectedDays = const [],
    required this.selectedTime,
    this.totalPrice = 0,
    this.paymentMethod = 'cash',
    this.paymentReference,
    this.paymentScreenshotUrl,
    required this.createdAt,
    this.paymentDeadline,
  });

  factory PendingPaymentModel.fromJson(Map<String, dynamic> json) {
    return PendingPaymentModel(
      bookingId: json['booking_id'] as String? ?? json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userName: json['full_name'] as String? ??
          json['user_name'] as String? ??
          'Member',
      userPhone: json['phone'] as String?,
      coachName: json['coach_name'] as String? ?? 'Coach',
      coachPhoto: json['coach_photo'] as String?,
      coachSpecialty: json['coach_specialty'] as String?,
      branchName: json['branch_name'] as String? ?? '',
      selectedDays: _parseStringList(json['selected_days']),
      selectedTime: json['selected_time'] as String? ?? 'Time not set',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      paymentReference: json['payment_reference'] as String?,
      paymentScreenshotUrl: json['payment_screenshot_url'] as String?,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      paymentDeadline: _parseDate(json['payment_deadline']),
    );
  }

  bool get isCash => paymentMethod.toLowerCase() == 'cash';

  bool get isInstaPay =>
      paymentMethod.toLowerCase() == 'instapay' ||
      paymentMethod.toLowerCase() == 'insta_pay';

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
