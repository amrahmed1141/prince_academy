import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/repositories/admin_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository repository;
  StreamSubscription? _subscription;

  AdminBloc({required this.repository}) : super(const AdminInitial()) {
    on<LoadPendingPayments>(_onLoadPendingPayments);
    on<FilterByMethod>(_onFilterByMethod);
    on<PendingPaymentsStreamUpdated>(_onStreamUpdated);
    on<PendingPaymentsStreamFailed>(_onStreamFailed);
    on<VerifyPayment>(_onVerifyPayment);
    on<RejectPayment>(_onRejectPayment);
    on<ClearAdminMessage>(_onClearMessage);
  }

  Future<void> _onLoadPendingPayments(
    LoadPendingPayments event,
    Emitter<AdminState> emit,
  ) async {
    await _subscription?.cancel();
    repository.ensureRealtimeSubscription();
    _subscription = repository.stream.listen(
      (payments) => add(PendingPaymentsStreamUpdated(payments)),
      onError: (Object error) {
        add(PendingPaymentsStreamFailed(error.toString()));
      },
    );

    emit(const PendingPaymentsLoading());

    try {
      final payments = await repository.refresh();
      emit(PendingPaymentsLoaded(payments: payments));
    } catch (e) {
      emit(AdminError(_messageFrom(e)));
    }
  }

  void _onFilterByMethod(FilterByMethod event, Emitter<AdminState> emit) {
    final current = state;
    if (current is PendingPaymentsLoaded) {
      emit(current.copyWith(filter: event.method, clearMessage: true));
    }
  }

  void _onStreamUpdated(
    PendingPaymentsStreamUpdated event,
    Emitter<AdminState> emit,
  ) {
    final current = state;
    if (current is PendingPaymentsLoaded) {
      emit(current.copyWith(payments: event.payments, clearMessage: true));
      return;
    }
    if (current is PaymentVerified) {
      emit(current.data.copyWith(payments: event.payments, clearMessage: true));
      return;
    }
    if (current is PaymentRejected) {
      emit(current.data.copyWith(payments: event.payments, clearMessage: true));
      return;
    }
    if (current is PaymentVerifying) {
      emit(current.data.copyWith(payments: event.payments, clearMessage: true));
      return;
    }
    emit(PendingPaymentsLoaded(payments: event.payments));
  }

  void _onStreamFailed(
    PendingPaymentsStreamFailed event,
    Emitter<AdminState> emit,
  ) {
    final current = state;
    if (current is PendingPaymentsLoaded) return;
    emit(AdminError(_messageFrom(event.message)));
  }

  // ADDED: verify_payment RPC via repository
  Future<void> _onVerifyPayment(
    VerifyPayment event,
    Emitter<AdminState> emit,
  ) async {
    final current = _loadedState();
    if (current == null) return;

    emit(PaymentVerifying(event.bookingId, current));

    try {
      await repository.verifyPayment(event.bookingId, notes: event.notes);

      final updated = current.copyWith(
        payments: current.payments
            .where((p) => p.bookingId != event.bookingId)
            .toList(),
        message: 'Payment verified successfully',
        isSuccessMessage: true,
      );
      emit(PaymentVerified(event.bookingId, updated));
      emit(updated);
    } catch (e) {
      emit(current.copyWith(
        message: _messageFrom(e),
        isSuccessMessage: false,
      ));
    }
  }

  // ADDED: reject_payment RPC via repository
  Future<void> _onRejectPayment(
    RejectPayment event,
    Emitter<AdminState> emit,
  ) async {
    final current = _loadedState();
    if (current == null) return;

    emit(current.copyWith(
      rejectingBookingId: event.bookingId,
      clearMessage: true,
    ));

    try {
      await repository.rejectPayment(event.bookingId, event.reason);

      final updated = current.copyWith(
        payments: current.payments
            .where((p) => p.bookingId != event.bookingId)
            .toList(),
        clearRejecting: true,
        message: 'Payment rejected',
        isSuccessMessage: true,
      );
      emit(PaymentRejected(event.bookingId, updated));
      emit(updated);
    } catch (e) {
      emit(current.copyWith(
        clearRejecting: true,
        message: _messageFrom(e),
        isSuccessMessage: false,
      ));
    }
  }

  void _onClearMessage(ClearAdminMessage event, Emitter<AdminState> emit) {
    final current = _loadedState();
    if (current != null) {
      emit(current.copyWith(clearMessage: true));
    }
  }

  PendingPaymentsLoaded? _loadedState() {
    return switch (state) {
      PendingPaymentsLoaded s => s,
      PaymentVerifying s => s.data,
      PaymentVerified s => s.data,
      PaymentRejected s => s.data,
      _ => null,
    };
  }

  String _messageFrom(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
