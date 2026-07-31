/// Actor that opens [UserFreezePage] — drives confirm CTA + RPC.
enum FreezeActor { admin, member }

class BookingFreezeContext {
  const BookingFreezeContext({
    required this.bookingId,
    required this.userId,
    this.subscriptionEnd,
    this.subscriptionStart,
    this.status,
  });

  final String bookingId;
  final String userId;
  final DateTime? subscriptionEnd;
  final DateTime? subscriptionStart;
  final String? status;

  factory BookingFreezeContext.fromJson(Map<String, dynamic> json) {
    return BookingFreezeContext(
      bookingId: json['booking_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      subscriptionEnd: _parseDate(json['subscription_end']),
      subscriptionStart: _parseDate(json['subscription_start']),
      status: json['status'] as String?,
    );
  }
}

class PendingFreezeRequest {
  const PendingFreezeRequest({
    required this.freezeId,
    required this.bookingId,
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required this.coachName,
    required this.sessionDates,
    required this.createdAt,
    this.currentSubscriptionEnd,
  });

  final String freezeId;
  final String bookingId;
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String coachName;
  final List<DateTime> sessionDates;
  final DateTime createdAt;
  final DateTime? currentSubscriptionEnd;

  int get sessionCount => sessionDates.length;

  factory PendingFreezeRequest.fromJson(Map<String, dynamic> json) {
    return PendingFreezeRequest(
      freezeId: json['freeze_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Member',
      avatarUrl: json['avatar_url'] as String?,
      coachName: json['coach_name'] as String? ?? 'Coach',
      sessionDates: _parseDateList(json['session_dates']),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      currentSubscriptionEnd: _parseDate(json['current_subscription_end']),
    );
  }
}

class ActiveBookingFreeze {
  const ActiveBookingFreeze({
    required this.freezeId,
    required this.bookingId,
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required this.coachName,
    required this.sessionDates,
    this.originalSubscriptionEnd,
    this.newSubscriptionEnd,
    this.approvedAt,
  });

  final String freezeId;
  final String bookingId;
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String coachName;
  final List<DateTime> sessionDates;
  final DateTime? originalSubscriptionEnd;
  final DateTime? newSubscriptionEnd;
  final DateTime? approvedAt;

  int get sessionCount => sessionDates.length;

  factory ActiveBookingFreeze.fromJson(Map<String, dynamic> json) {
    return ActiveBookingFreeze(
      freezeId: json['freeze_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Member',
      avatarUrl: json['avatar_url'] as String?,
      coachName: json['coach_name'] as String? ?? 'Coach',
      sessionDates: _parseDateList(json['session_dates']),
      originalSubscriptionEnd: _parseDate(json['original_subscription_end']),
      newSubscriptionEnd: _parseDate(json['new_subscription_end']),
      approvedAt: _parseDateTime(json['approved_at']),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) {
    return DateTime(value.year, value.month, value.day);
  }
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

List<DateTime> _parseDateList(dynamic value) {
  if (value == null) return const [];
  if (value is! List) return const [];
  final out = <DateTime>[];
  for (final item in value) {
    final d = _parseDate(item);
    if (d != null) out.add(d);
  }
  return out;
}

String formatFreezeDateParam(DateTime date) {
  final local = date.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String formatFreezeDisplayDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d/$m/${local.year}';
}
