import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/services/user_qr_service.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_event.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _repository;

  BookingBloc(this._repository) : super(const BookingInitial()) {
    on<LoadBookingData>(_onLoadBookingData);
    on<ToggleDay>(_onToggleDay);
    on<SelectPaymentMethod>(_onSelectPaymentMethod);
    on<ClearMinSessionsWarning>(_onClearMinSessionsWarning);
    on<SubmitBooking>(_onSubmitBooking);
  }

  Future<void> _onLoadBookingData(
    LoadBookingData event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    try {
      // TODO: If multiple active coach_sessions rows exist, clarify which one
      // should drive booking; for now we use the first active row.
      final session = await _repository.getActiveSession(event.coachId);
      if (session == null) {
        emit(const BookingError('No schedule available for this coach.'));
        return;
      }

      final days = session.days;
      if (days.isEmpty) {
        emit(const BookingError('No schedule available for this coach.'));
        return;
      }

      final sessionsPerWeek = session.sessionsPerWeek;
      final isLocked = sessionsPerWeek <= 2;
      final initialSelectedDays = isLocked
          ? List<String>.from(days)
          : days.length >= 2
              ? days.take(2).toList()
              : List<String>.from(days);
      final time =
          session.timeSlots.isNotEmpty ? session.timeSlots.first : null;
      final total = _calculateTotal(
        session.pricePerSession,
        initialSelectedDays.length,
      );

      emit(
        BookingLoaded(
          session: session,
          coachName: event.coachName ?? session.coachName ?? 'Coach',
          coachImage: event.coachImage ?? session.coachPhotoUrl ?? '',
          selectedDays: initialSelectedDays,
          selectedTime: time,
          isLocked: isLocked,
          paymentMethod: PaymentMethod.cash,
          totalPrice: total,
        ),
      );
    } catch (e) {
      emit(BookingError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  BookingLoaded? _loadedFromState(BookingState state) {
    return switch (state) {
      BookingLoaded s => s,
      BookingSubmitting s => s.data,
      BookingSubmitFailed s => s.data,
      _ => null,
    };
  }

  void _onToggleDay(ToggleDay event, Emitter<BookingState> emit) {
    final current = _loadedFromState(state);
    if (current == null || current.isLocked) return;

    final day = event.day;
    if (current.selectedDays.contains(day)) {
      if (current.selectedDays.length <= 2) {
        emit(current.copyWith(showMinSessionsWarning: true));
        return;
      }

      final updatedDays =
          current.selectedDays.where((d) => d != day).toList();
      emit(
        current.copyWith(
          selectedDays: updatedDays,
          totalPrice: _calculateTotal(
            current.session.pricePerSession,
            updatedDays.length,
          ),
          showMinSessionsWarning: false,
        ),
      );
      return;
    }

    final updatedDays = [...current.selectedDays, day];
    emit(
      current.copyWith(
        selectedDays: updatedDays,
        totalPrice: _calculateTotal(
          current.session.pricePerSession,
          updatedDays.length,
        ),
        showMinSessionsWarning: false,
      ),
    );
  }

  void _onSelectPaymentMethod(
    SelectPaymentMethod event,
    Emitter<BookingState> emit,
  ) {
    final current = _loadedFromState(state);
    if (current == null) return;

    emit(current.copyWith(paymentMethod: event.method));
  }

  void _onClearMinSessionsWarning(
    ClearMinSessionsWarning event,
    Emitter<BookingState> emit,
  ) {
    final current = _loadedFromState(state);
    if (current == null || !current.showMinSessionsWarning) return;

    emit(current.copyWith(showMinSessionsWarning: false));
  }

  Future<void> _onSubmitBooking(
    SubmitBooking event,
    Emitter<BookingState> emit,
  ) async {
    final current = _loadedFromState(state);
    if (current == null) return;
    if (!current.canContinue) return;

    emit(BookingSubmitting(current));

    try {
      final booking = BookingModel(
        coachId: current.session.coachId,
        sessionId: current.session.id,
        coachName: current.coachName,
        coachImage: current.coachImage,
        sessionType: current.session.sessionType,
        selectedDays: current.selectedDays,
        selectedTime: current.selectedTime ?? current.fixedTime,
        paymentMethod: current.paymentMethod!.name,
        totalPrice: current.totalPrice,
        status: 'pending',
      );

      final saved = await _repository.submitBooking(booking);

      String? qrCode;
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          qrCode = await _repository.ensureUserQrCode(userId);
          sl<UserQrService>().setQrCode(qrCode);
        }
      } catch (_) {
        // Booking succeeded; QR assignment can be retried from profile later.
      }

      emit(BookingSuccess(saved, qrCode: qrCode));
    } catch (e) {
      emit(
        BookingSubmitFailed(
          current,
          e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  double _calculateTotal(double pricePerSession, int dayCount) {
    return dayCount * pricePerSession;
  }
}
