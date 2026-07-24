class ActiveUser {
  final String userId;
  final String fullName;
  final String? phone;
  final String? qrCode;
  final int totalBookings;
  final int activeBookings;
  final int expiredBookings;
  final DateTime? latestSubscriptionEnd;
  final bool hasPendingPayment;

  const ActiveUser({
    required this.userId,
    required this.fullName,
    this.phone,
    this.qrCode,
    required this.totalBookings,
    required this.activeBookings,
    required this.expiredBookings,
    this.latestSubscriptionEnd,
    this.hasPendingPayment = false,
  });

  factory ActiveUser.fromJson(Map<String, dynamic> json) {
    return ActiveUser(
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Unknown Member',
      phone: json['phone'] as String?,
      qrCode: json['qr_code'] as String?,
      totalBookings: (json['total_bookings'] as num?)?.toInt() ?? 0,
      activeBookings: (json['active_bookings'] as num?)?.toInt() ?? 0,
      expiredBookings: (json['expired_bookings'] as num?)?.toInt() ?? 0,
      latestSubscriptionEnd: _parseDate(json['latest_subscription_end']),
      hasPendingPayment: json['has_pending_payment'] as bool? ?? false,
    );
  }

  ActiveUser copyWith({bool? hasPendingPayment}) {
    return ActiveUser(
      userId: userId,
      fullName: fullName,
      phone: phone,
      qrCode: qrCode,
      totalBookings: totalBookings,
      activeBookings: activeBookings,
      expiredBookings: expiredBookings,
      latestSubscriptionEnd: latestSubscriptionEnd,
      hasPendingPayment: hasPendingPayment ?? this.hasPendingPayment,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
