import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/core/helpers/payment_reference_helper.dart';
import 'package:prince_academy/core/helpers/session_schedule_helper.dart';
import 'package:prince_academy/core/helpers/subscription_pricing.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/services/member_data_sync.dart';
import 'package:prince_academy/core/services/user_qr_service.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_event.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _repository;

  BookingBloc(
    this._repository, {
    List<String> bookedCoachIds = const [],
  }) : super(BookingInitial(bookedCoachIds: bookedCoachIds)) {
    on<LoadUserActiveBookings>(_onLoadUserActiveBookings); // ADDED
    on<CheckDuplicateBooking>(_onCheckDuplicateBooking); // ADDED
    on<LoadCoachBooking>(_onLoadCoachBooking);
    on<SelectCoach>(_onSelectCoach);
    on<SelectDays>(_onSelectDays);
    on<SelectStartDate>(_onSelectStartDate);
    on<SelectPaymentMethod>(_onSelectPaymentMethod);
    on<CreateBooking>(_onCreateBooking);
    on<UploadScreenshot>(_onUploadScreenshot);
    on<ConfirmInstaPayPayment>(_onConfirmInstaPayPayment);
  }

  // ADDED: cache coach IDs with active/pending bookings on app start
  Future<void> _onLoadUserActiveBookings(
    LoadUserActiveBookings event,
    Emitter<BookingState> emit,
  ) async {
    try {
      final ids = await _repository.getUserActiveCoachIds();
      emit(_withBookedCoachIds(state, ids));
    } catch (_) {
      emit(_withBookedCoachIds(state, state.bookedCoachIds));
    }
  }

  // ADDED: RPC safety check before opening booking wizard
  Future<void> _onCheckDuplicateBooking(
    CheckDuplicateBooking event,
    Emitter<BookingState> emit,
  ) async {
    final cachedIds = state.bookedCoachIds;
    emit(BookingCheckLoading(bookedCoachIds: cachedIds));

    try {
      final cachedDuplicate = cachedIds.contains(event.coachId);
      final isDuplicate = cachedDuplicate ||
          await _repository.hasActiveBookingWithCoach(event.coachId);

      if (isDuplicate) {
        final details =
            await _repository.getActiveBookingForCoach(event.coachId);
        final updatedIds = cachedDuplicate
            ? cachedIds
            : [...cachedIds, event.coachId];

        emit(
          BookingCheckResult(
            isDuplicate: true,
            existingBookingId: details?.bookingId,
            existingCoachName:
                details?.coachName ?? event.coachName ?? 'this coach',
            bookedCoachIds: updatedIds,
          ),
        );

        if (!cachedDuplicate) {
          add(const LoadUserActiveBookings());
        }
        return;
      }

      add(
        LoadCoachBooking(
          coachId: event.coachId,
          coachName: event.coachName,
          coachImage: event.coachImage,
          specialty: event.specialty,
          branchId: event.branchId,
        ),
      );
    } catch (e) {
      emit(
        BookingError(
          e.toString().replaceFirst('Exception: ', ''),
          bookedCoachIds: cachedIds,
        ),
      );
    }
  }

  Future<void> _onLoadCoachBooking(
    LoadCoachBooking event,
    Emitter<BookingState> emit,
  ) async {
    final bookedCoachIds = state.bookedCoachIds;
    emit(BookingLoading(bookedCoachIds: bookedCoachIds));
    try {
      final session = await _repository.getActiveSession(
        event.coachId,
        branchId: event.branchId,
      );
      if (session == null || session.days.isEmpty) {
        emit(BookingError(
          event.branchId != null && event.branchId!.isNotEmpty
              ? 'No schedule available for this coach at the selected branch.'
              : 'No schedule available for this coach.',
          bookedCoachIds: bookedCoachIds,
        ));
        return;
      }

      final coach = BookingCoach(
        id: event.coachId,
        name: event.coachName ?? session.coachName ?? 'Coach',
        photoUrl: event.coachImage ?? session.coachPhotoUrl,
        specialty: event.specialty ??
            (session.coachSpecialty?.trim().isNotEmpty == true
                ? session.coachSpecialty!
                : 'MMA'),
        branchId: session.branchId ?? event.branchId,
        branchName: session.branchName,
      );

      final availableDays = List<String>.from(session.days);
      final time =
          session.timeSlots.isNotEmpty ? session.timeSlots.first : 'Time not set';

      final initialSelected = availableDays.length >= 2
          ? availableDays.take(2).toList()
          : List<String>.from(availableDays);

      emit(
        BookingStep1CoachSelected(
          BookingWizardData(
            coach: coach,
            session: session,
            availableDays: availableDays,
            selectedDays: initialSelected,
            sessionTime: time,
            totalPrice: SubscriptionPricing.monthlyPrice(
              session.pricePerSession,
              initialSelected.length,
            ),
          ),
          bookedCoachIds: bookedCoachIds,
        ),
      );
    } catch (e) {
      emit(BookingError(
        e.toString().replaceFirst('Exception: ', ''),
        bookedCoachIds: bookedCoachIds,
      ));
    }
  }

  void _onSelectCoach(SelectCoach event, Emitter<BookingState> emit) {
    add(LoadCoachBooking(coachId: event.coach.id));
  }

  void _onSelectDays(SelectDays event, Emitter<BookingState> emit) {
    final current = _wizardDataFromState(state);
    if (current == null) return;

    final selected = List<String>.from(event.days);
    final total = SubscriptionPricing.monthlyPrice(
      current.session.pricePerSession,
      selected.length,
    );

    final updated = current.copyWith(
      selectedDays: selected,
      totalPrice: total,
      startDate: null,
      endDate: null,
      sessionDates: const [],
    );

    emit(
      BookingStep2DaysSelected(
        data: updated,
        availableDays: current.availableDays,
        selectedDays: selected,
        estimatedSessions: SubscriptionPricing.monthlySessionCount(
          selected.length,
        ),
        bookedCoachIds: state.bookedCoachIds,
      ),
    );
  }

  void _onSelectStartDate(SelectStartDate event, Emitter<BookingState> emit) {
    final current = _wizardDataFromState(state);
    if (current == null || current.selectedDays.length < 2) return;

    final start = SessionScheduleHelper.dateOnly(event.date);
    final end = SessionScheduleHelper.subscriptionEndDate(start);
    final sessionDates = SessionScheduleHelper.generateSessionDates(
      startDate: start,
      selectedDays: current.selectedDays,
    );

    if (sessionDates.isEmpty) {
      emit(BookingError(
        'No sessions fall within this month for the selected start date.',
        bookedCoachIds: state.bookedCoachIds,
      ));
      return;
    }

    final updated = current.copyWith(
      startDate: start,
      endDate: end,
      sessionDates: sessionDates,
    );

    emit(
      BookingStep3DateSelected(
        data: updated,
        startDate: start,
        endDate: end,
        sessionDates: sessionDates,
        sessionCount: sessionDates.length,
        bookedCoachIds: state.bookedCoachIds,
      ),
    );
  }

  void _onSelectPaymentMethod(
    SelectPaymentMethod event,
    Emitter<BookingState> emit,
  ) {
    final step3 = _step3DateFromState(state);
    if (step3 == null) return;

    final updated = step3.data.copyWith(paymentMethod: event.method);

    emit(
      BookingStep4PaymentSelected(
        data: updated,
        startDate: step3.startDate,
        endDate: step3.endDate,
        sessionDates: step3.sessionDates,
        sessionCount: step3.sessionCount,
        paymentMethod: event.method,
        bookedCoachIds: state.bookedCoachIds,
      ),
    );
  }

  Future<void> _onCreateBooking(
    CreateBooking event,
    Emitter<BookingState> emit,
  ) async {
    final step4 = _step4PaymentFromState(state);
    if (step4 == null) return;

    final data = step4.data;
    final branchId = data.coach.branchId ?? data.session.branchId;
    if (branchId == null || branchId.isEmpty) {
      emit(BookingError(
        'Branch not configured for this coach.',
        bookedCoachIds: state.bookedCoachIds,
      ));
      return;
    }

    emit(BookingCreating(data, bookedCoachIds: state.bookedCoachIds));

    try {
      final reference = step4.paymentMethod == PaymentMethod.instapay.name
          ? PaymentReferenceHelper.generate(
              coachName: data.coach.name,
              sessionTime: data.sessionTime,
              startDate: step4.startDate,
            )
          : null;

      final saved = await _repository.createBookingWithSchedule(
        coachId: data.coach.id,
        branchId: branchId,
        days: data.selectedDays,
        time: data.sessionTime,
        startDate: step4.startDate,
        price: data.totalPrice,
        method: step4.paymentMethod,
        paymentReference: reference,
      );

      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final qrCode = await _repository.ensureUserQrCode(userId);
          sl<UserQrService>().setQrCode(qrCode);
        }
      } catch (_) {}

      final period = SessionScheduleHelper.formatPeriod(
        step4.startDate,
        step4.endDate,
      );

      final message = step4.paymentMethod == PaymentMethod.cash.name
          ? _cashMessage(saved, period)
          : 'Booking created. Complete your InstaPay transfer to activate.';

      emit(
        BookingCreated(
          booking: saved.copyWith(
            coachName: data.coach.name,
            paymentReference: saved.paymentReference ?? reference,
          ),
          message: message,
          data: data.copyWith(createdBooking: saved),
          bookedCoachIds: state.bookedCoachIds,
        ),
      );

      MemberDataSync.afterBookingMutationUnawaited();
      add(const LoadUserActiveBookings());
    } catch (e) {
      emit(BookingError(
        e.toString().replaceFirst('Exception: ', ''),
        bookedCoachIds: state.bookedCoachIds,
      ));
      emit(
        BookingStep4PaymentSelected(
          data: data,
          startDate: step4.startDate,
          endDate: step4.endDate,
          sessionDates: step4.sessionDates,
          sessionCount: step4.sessionCount,
          paymentMethod: step4.paymentMethod,
          bookedCoachIds: state.bookedCoachIds,
        ),
      );
    }
  }

  Future<void> _onUploadScreenshot(
    UploadScreenshot event,
    Emitter<BookingState> emit,
  ) async {
    final created = state is BookingCreated ? state as BookingCreated : null;
    final bookingId = created?.booking.id;
    if (bookingId == null || bookingId.isEmpty) return;

    try {
      await _repository.uploadPaymentScreenshot(
        bookingId: bookingId,
        file: event.file,
      );
    } catch (e) {
      emit(BookingError(
        e.toString().replaceFirst('Exception: ', ''),
        bookedCoachIds: state.bookedCoachIds,
      ));
      if (created != null) emit(created);
    }
  }

  Future<void> _onConfirmInstaPayPayment(
    ConfirmInstaPayPayment event,
    Emitter<BookingState> emit,
  ) async {
    final created = state is BookingCreated ? state as BookingCreated : null;
    final bookingId = created?.booking.id;
    if (bookingId == null || bookingId.isEmpty) return;

    try {
      await _repository.confirmInstaPayPayment(bookingId);
      MemberDataSync.afterBookingMutationUnawaited();
    } catch (e) {
      emit(BookingError(
        e.toString().replaceFirst('Exception: ', ''),
        bookedCoachIds: state.bookedCoachIds,
      ));
      if (created != null) emit(created);
    }
  }

  String _cashMessage(BookingModel booking, String period) {
    final amount = booking.totalPrice.toStringAsFixed(0);
    final deadline = booking.paymentDeadline;
    final deadlineText = deadline != null
        ? DateFormat('MMMM d, yyyy').format(deadline)
        : DateFormat('MMMM d, yyyy')
            .format(DateTime.now().add(const Duration(days: 3)));
    return 'Pay $amount EGP at the academy within 3 days. Deadline: $deadlineText. Subscription: $period';
  }

  // ADDED: preserve wizard/check state while updating bookedCoachIds cache
  BookingState _withBookedCoachIds(BookingState current, List<String> ids) {
    if (current.bookedCoachIds == ids) return current;

    return switch (current) {
      BookingInitial() => BookingInitial(bookedCoachIds: ids),
      BookingLoading() => BookingLoading(bookedCoachIds: ids),
      BookingCheckLoading() => BookingCheckLoading(bookedCoachIds: ids),
      BookingCheckResult s => BookingCheckResult(
          isDuplicate: s.isDuplicate,
          existingBookingId: s.existingBookingId,
          existingCoachName: s.existingCoachName,
          bookedCoachIds: ids,
        ),
      BookingStep1CoachSelected s =>
        BookingStep1CoachSelected(s.data, bookedCoachIds: ids),
      BookingStep2DaysSelected s => BookingStep2DaysSelected(
          data: s.data,
          availableDays: s.availableDays,
          selectedDays: s.selectedDays,
          estimatedSessions: s.estimatedSessions,
          bookedCoachIds: ids,
        ),
      BookingStep3DateSelected s => BookingStep3DateSelected(
          data: s.data,
          startDate: s.startDate,
          endDate: s.endDate,
          sessionDates: s.sessionDates,
          sessionCount: s.sessionCount,
          bookedCoachIds: ids,
        ),
      BookingStep4PaymentSelected s => BookingStep4PaymentSelected(
          data: s.data,
          startDate: s.startDate,
          endDate: s.endDate,
          sessionDates: s.sessionDates,
          sessionCount: s.sessionCount,
          paymentMethod: s.paymentMethod,
          bookedCoachIds: ids,
        ),
      BookingCreating s => BookingCreating(s.data, bookedCoachIds: ids),
      BookingCreated s => BookingCreated(
          booking: s.booking,
          message: s.message,
          data: s.data,
          bookedCoachIds: ids,
        ),
      BookingError s => BookingError(s.message, bookedCoachIds: ids),
      BookingState() => BookingInitial(bookedCoachIds: ids),
    };
  }

  BookingWizardData? _wizardDataFromState(BookingState state) {
    return switch (state) {
      BookingStep1CoachSelected s => s.data,
      BookingStep2DaysSelected s => s.data,
      BookingStep3DateSelected s => s.data,
      BookingStep4PaymentSelected s => s.data,
      BookingCreating s => s.data,
      BookingCreated s => s.data,
      _ => null,
    };
  }

  BookingStep3DateSelected? _step3DateFromState(BookingState state) {
    return switch (state) {
      BookingStep3DateSelected s => s,
      BookingStep4PaymentSelected s => BookingStep3DateSelected(
          data: s.data,
          startDate: s.startDate,
          endDate: s.endDate,
          sessionDates: s.sessionDates,
          sessionCount: s.sessionCount,
          bookedCoachIds: s.bookedCoachIds,
        ),
      _ => null,
    };
  }

  BookingStep4PaymentSelected? _step4PaymentFromState(BookingState state) {
    return state is BookingStep4PaymentSelected ? state : null;
  }
}
