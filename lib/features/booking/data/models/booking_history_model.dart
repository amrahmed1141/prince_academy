class BookingHistoryModel {
  final String bookingId;
  final String userId;
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
  final String bookingStatus;
  final DateTime? createdAt;
  final int attendedSessions;
  final int totalSessions;
  final String displayStatus;

  const BookingHistoryModel({
    required this.bookingId,
    required this.userId,
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
    this.bookingStatus = 'pending',
    this.createdAt,
    this.attendedSessions = 0,
    this.totalSessions = 0,
    this.displayStatus = 'pending',
  });

  factory BookingHistoryModel.fromJson(Map<String, dynamic> json) {
    return BookingHistoryModel(
      bookingId: json['booking_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      coachId: json['coach_id'] as String? ?? '',
      coachName: json['coach_name'] as String? ?? 'Coach',
      coachPhoto: json['coach_photo'] as String?,
      coachSpecialty: json['coach_specialty'] as String?,
      selectedDays: _parseStringList(json['selected_days']),
      selectedTime: json['selected_time'] as String?,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String?,
      subscriptionStart: _parseDate(json['subscription_start']),
      subscriptionEnd: _parseDate(json['subscription_end']),
      bookingStatus: json['booking_status'] as String? ?? 'pending',
      createdAt: _parseDate(json['created_at']),
      attendedSessions: (json['attended_sessions'] as num?)?.toInt() ?? 0,
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      displayStatus: json['display_status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'user_id': userId,
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
      'booking_status': bookingStatus,
      'created_at': createdAt?.toIso8601String(),
      'attended_sessions': attendedSessions,
      'total_sessions': totalSessions,
      'display_status': displayStatus,
    };
  }

  BookingHistoryModel copyWith({
    String? bookingId,
    String? userId,
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
    String? bookingStatus,
    DateTime? createdAt,
    int? attendedSessions,
    int? totalSessions,
    String? displayStatus,
  }) {
    return BookingHistoryModel(
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
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
      bookingStatus: bookingStatus ?? this.bookingStatus,
      createdAt: createdAt ?? this.createdAt,
      attendedSessions: attendedSessions ?? this.attendedSessions,
      totalSessions: totalSessions ?? this.totalSessions,
      displayStatus: displayStatus ?? this.displayStatus,
    );
  }

  String get paymentStatusText {
    if (bookingStatus == 'pending') return 'Payment pending';
    final method = paymentMethod?.toLowerCase();
    if (method == 'cash' || method == 'instapay') return 'Paid';
    return 'Payment pending';
  }

  /// Resolves UI/filter status when the view still reports `pending` but
  /// the member has already attended sessions (e.g. cash booking awaiting admin).
  String get effectiveDisplayStatus {
    if (totalSessions > 0 && attendedSessions >= totalSessions) {
      return 'completed';
    }

    final now = DateTime.now();
    final end = subscriptionEnd;
    if (end != null) {
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
      if (now.isAfter(endOfDay) && attendedSessions < totalSessions) {
        return 'expired';
      }
    }

    if (attendedSessions > 0) return 'active';

    if (bookingStatus == 'pending') return 'pending';

    final start = subscriptionStart;
    if (start != null && end != null) {
      final startOfDay = DateTime(start.year, start.month, start.day);
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
      if (!now.isBefore(startOfDay) && !now.isAfter(endOfDay)) {
        return 'active';
      }
      if (now.isAfter(endOfDay)) return 'expired';
    }

    return displayStatus;
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
