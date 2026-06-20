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
}

class BookingModel {
  final String? id;
  final String coachId;
  final String? sessionId;
  final String? coachName;
  final String? coachImage;
  final String? sessionType;
  final List<String> selectedDays;
  final String? selectedTime;
  final String? paymentMethod;
  final double totalPrice;
  final String status;

  const BookingModel({
    this.id,
    required this.coachId,
    this.sessionId,
    this.coachName,
    this.coachImage,
    this.sessionType,
    this.selectedDays = const [],
    this.selectedTime,
    this.paymentMethod,
    this.totalPrice = 0,
    this.status = 'pending',
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String?,
      coachId: json['coach_id'] as String? ?? '',
      sessionId: json['session_id'] as String?,
      selectedDays: _parseStringList(json['selected_days']),
      selectedTime: json['selected_time'] as String?,
      paymentMethod: json['payment_method'] as String?,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'coach_id': coachId,
      if (sessionId != null) 'session_id': sessionId,
      'selected_days': selectedDays,
      if (selectedTime != null) 'selected_time': selectedTime,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      'total_price': totalPrice,
      'status': status,
    };
  }

  Map<String, dynamic> toInsertJson({required String userId}) {
    return {
      'user_id': userId,
      'coach_id': coachId,
      if (sessionId != null) 'session_id': sessionId,
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
    String? coachName,
    String? coachImage,
    String? sessionType,
    List<String>? selectedDays,
    String? selectedTime,
    String? paymentMethod,
    double? totalPrice,
    String? status,
  }) {
    return BookingModel(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      sessionId: sessionId ?? this.sessionId,
      coachName: coachName ?? this.coachName,
      coachImage: coachImage ?? this.coachImage,
      sessionType: sessionType ?? this.sessionType,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedTime: selectedTime ?? this.selectedTime,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
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
