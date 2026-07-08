import 'package:equatable/equatable.dart';

enum PaymentMethod { cash, instapay }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.instapay => 'InstaPay',
      };

  String get subtitle => switch (this) {
        PaymentMethod.cash => 'Pay at the academy',
        PaymentMethod.instapay => 'Pay via InstaPay transfer',
      };

  String get apiValue => name;
}

class BookingModel {
  final String? id;
  final String coachId;
  final String? sessionId;
  final String? branchId;
  final String? coachName;
  final String? coachImage;
  final String? sessionType;
  final List<String> selectedDays;
  final String? selectedTime;
  final String? paymentMethod;
  final double totalPrice;
  final String status;
  // ADDED: subscription & payment fields from create_booking_with_schedule
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final String? paymentStatus;
  final String? paymentReference;
  final DateTime? paymentDeadline;

  const BookingModel({
    this.id,
    required this.coachId,
    this.sessionId,
    this.branchId,
    this.coachName,
    this.coachImage,
    this.sessionType,
    this.selectedDays = const [],
    this.selectedTime,
    this.paymentMethod,
    this.totalPrice = 0,
    this.status = 'pending',
    this.subscriptionStart,
    this.subscriptionEnd,
    this.paymentStatus,
    this.paymentReference,
    this.paymentDeadline,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String?,
      coachId: json['coach_id'] as String? ?? '',
      sessionId: json['session_id'] as String?,
      branchId: json['branch_id'] as String?,
      selectedDays: _parseStringList(json['selected_days']),
      selectedTime: json['selected_time'] as String?,
      paymentMethod: json['payment_method'] as String?,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      subscriptionStart: _parseDate(json['subscription_start'] ?? json['start_date']),
      subscriptionEnd: _parseDate(json['subscription_end']),
      paymentStatus: json['payment_status'] as String?,
      paymentReference: json['payment_reference'] as String?,
      paymentDeadline: _parseDate(json['payment_deadline']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'coach_id': coachId,
      if (sessionId != null) 'session_id': sessionId,
      if (branchId != null) 'branch_id': branchId,
      'selected_days': selectedDays,
      if (selectedTime != null) 'selected_time': selectedTime,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      'total_price': totalPrice,
      'status': status,
      if (subscriptionStart != null)
        'subscription_start': subscriptionStart!.toIso8601String(),
      if (subscriptionEnd != null)
        'subscription_end': subscriptionEnd!.toIso8601String(),
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (paymentReference != null) 'payment_reference': paymentReference,
      if (paymentDeadline != null)
        'payment_deadline': paymentDeadline!.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson({required String userId}) {
    return {
      'user_id': userId,
      'coach_id': coachId,
      if (sessionId != null) 'session_id': sessionId,
      if (branchId != null) 'branch_id': branchId,
      'selected_days': selectedDays,
      'selected_time': selectedTime,
      'payment_method': paymentMethod,
      'total_price': totalPrice,
      'status': status,
    };
  }

  BookingModel copyWith({
    String? id,
    String? coachId,
    String? sessionId,
    String? branchId,
    String? coachName,
    String? coachImage,
    String? sessionType,
    List<String>? selectedDays,
    String? selectedTime,
    String? paymentMethod,
    double? totalPrice,
    String? status,
    DateTime? subscriptionStart,
    DateTime? subscriptionEnd,
    String? paymentStatus,
    String? paymentReference,
    DateTime? paymentDeadline,
  }) {
    return BookingModel(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      sessionId: sessionId ?? this.sessionId,
      branchId: branchId ?? this.branchId,
      coachName: coachName ?? this.coachName,
      coachImage: coachImage ?? this.coachImage,
      sessionType: sessionType ?? this.sessionType,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedTime: selectedTime ?? this.selectedTime,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      subscriptionStart: subscriptionStart ?? this.subscriptionStart,
      subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentDeadline: paymentDeadline ?? this.paymentDeadline,
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

/// Legacy display model kept for coach header navigation compatibility.
class MMABookingModel {
  final String? coachId;
  final String coachName;
  final String coachImage;
  final String? specialty;
  final String coachWhatsapp;

  const MMABookingModel({
    this.coachId,
    required this.coachName,
    required this.coachImage,
    this.specialty,
    required this.coachWhatsapp,
  });
}

/// Selected coach for the 3-step booking wizard.
class BookingCoach extends Equatable {
  final String id;
  final String name;
  final String? photoUrl;
  final String specialty;
  final String? branchId;
  final String? branchName;

  const BookingCoach({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.specialty,
    this.branchId,
    this.branchName,
  });

  @override
  List<Object?> get props => [id, name, photoUrl, specialty, branchId, branchName];
}
