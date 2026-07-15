import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class PendingPaymentsLoading extends AdminState {
  const PendingPaymentsLoading();
}

class PendingPaymentsLoaded extends AdminState {
  final List<PendingPaymentModel> payments;
  final String filter;
  final String? verifyingBookingId;
  final String? rejectingBookingId;
  final String? message;
  final bool isSuccessMessage;
  final bool isRefreshing;

  const PendingPaymentsLoaded({
    required this.payments,
    this.filter = 'all',
    this.verifyingBookingId,
    this.rejectingBookingId,
    this.message,
    this.isSuccessMessage = false,
    this.isRefreshing = false,
  });

  List<PendingPaymentModel> get filteredPayments {
    if (filter == 'all') return payments;
    return payments
        .where((p) => p.paymentMethod.toLowerCase() == filter)
        .toList();
  }

  PendingPaymentsLoaded copyWith({
    List<PendingPaymentModel>? payments,
    String? filter,
    String? verifyingBookingId,
    String? rejectingBookingId,
    bool clearVerifying = false,
    bool clearRejecting = false,
    String? message,
    bool? isSuccessMessage,
    bool clearMessage = false,
    bool? isRefreshing,
  }) {
    return PendingPaymentsLoaded(
      payments: payments ?? this.payments,
      filter: filter ?? this.filter,
      verifyingBookingId:
          clearVerifying ? null : verifyingBookingId ?? this.verifyingBookingId,
      rejectingBookingId:
          clearRejecting ? null : rejectingBookingId ?? this.rejectingBookingId,
      message: clearMessage ? null : message ?? this.message,
      isSuccessMessage: isSuccessMessage ?? this.isSuccessMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        payments,
        filter,
        verifyingBookingId,
        rejectingBookingId,
        message,
        isSuccessMessage,
        isRefreshing,
      ];
}

class PaymentVerifying extends AdminState {
  final String bookingId;
  final PendingPaymentsLoaded data;

  const PaymentVerifying(this.bookingId, this.data);

  @override
  List<Object?> get props => [bookingId, data];
}

class PaymentVerified extends AdminState {
  final String bookingId;
  final PendingPaymentsLoaded data;

  const PaymentVerified(this.bookingId, this.data);

  @override
  List<Object?> get props => [bookingId, data];
}

class PaymentRejected extends AdminState {
  final String bookingId;
  final PendingPaymentsLoaded data;

  const PaymentRejected(this.bookingId, this.data);

  @override
  List<Object?> get props => [bookingId, data];
}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}
