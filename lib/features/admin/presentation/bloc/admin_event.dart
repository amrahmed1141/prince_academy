import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingPayments extends AdminEvent {
  const LoadPendingPayments();
}

class FilterByMethod extends AdminEvent {
  final String method;

  const FilterByMethod(this.method);

  @override
  List<Object?> get props => [method];
}

class PendingPaymentsStreamUpdated extends AdminEvent {
  final List<PendingPaymentModel> payments;

  const PendingPaymentsStreamUpdated(this.payments);

  @override
  List<Object?> get props => [payments];
}

class PendingPaymentsStreamFailed extends AdminEvent {
  final String message;

  const PendingPaymentsStreamFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class VerifyPayment extends AdminEvent {
  final String bookingId;
  final String? notes;

  const VerifyPayment(this.bookingId, {this.notes});

  @override
  List<Object?> get props => [bookingId, notes];
}

class RejectPayment extends AdminEvent {
  final String bookingId;
  final String reason;

  const RejectPayment(this.bookingId, {required this.reason});

  @override
  List<Object?> get props => [bookingId, reason];
}

class ClearAdminMessage extends AdminEvent {
  const ClearAdminMessage();
}
