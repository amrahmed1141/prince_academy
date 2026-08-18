import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/helpers/payment_reference_helper.dart';
import 'package:prince_academy/core/helpers/session_schedule_helper.dart';
import 'package:prince_academy/core/services/member_data_sync.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';

class BookingRenewCubit extends Cubit<BookingRenewState> {
  BookingRenewCubit(this._repository) : super(const BookingRenewState.initial());

  final BookingRepository _repository;

  /// Booking id opened from history (not the renew prompt queue).
  /// Removed from [queue] if the member backs out without renewing.
  String? _manualRenewBookingId;

  /// Cancel on the prompt only hides it for this app session.
  /// Next cold start can show the card again until the member renews.
  final Set<String> _sessionDismissedIds = {};

  void _emitSafe(BookingRenewState nextState) {
    if (isClosed) return;
    emit(nextState);
  }

  Future<void> load() async {
    if (state.isFlowOpen || state.isSubmitting || state.isDismissing) return;

    _emitSafe(state.copyWith(isLoading: true, clearError: true));
    try {
      final queue = (await _repository.getRenewableBookings())
          .where((item) => !_sessionDismissedIds.contains(item.bookingId))
          .toList();
      _emitSafe(
        state.copyWith(
          isLoading: false,
          queue: queue,
          clearCreated: true,
        ),
      );
    } catch (error) {
      _emitSafe(
        state.copyWith(
          isLoading: false,
          errorMessage: _message(error),
        ),
      );
    }
  }

  Future<void> dismissCurrent() async {
    final current = state.current;
    if (current == null || state.isDismissing) return;

    _sessionDismissedIds.add(current.bookingId);
    _emitSafe(
      state.copyWith(
        isDismissing: false,
        queue: _without(state.queue, current.bookingId),
        isFlowOpen: false,
        clearSchedule: true,
        clearError: true,
      ),
    );
  }

  void openRenewFlow() {
    final current = state.current;
    if (current == null) return;
    _manualRenewBookingId = null;
    _emitSafe(
      state.copyWith(
        isFlowOpen: true,
        paymentMethod: _methodFrom(current.paymentMethod),
        clearSchedule: true,
        clearError: true,
        clearCreated: true,
      ),
    );
  }

  /// Opens the same renew wizard for a specific history booking (e.g. Expired).
  void startRenewFor(BookingHistoryModel booking) {
    final alreadyQueued =
        state.queue.any((item) => item.bookingId == booking.bookingId);
    _manualRenewBookingId = alreadyQueued ? null : booking.bookingId;

    final queue = [
      booking,
      ...state.queue.where((item) => item.bookingId != booking.bookingId),
    ];

    _emitSafe(
      state.copyWith(
        queue: queue,
        isFlowOpen: true,
        paymentMethod: _methodFrom(booking.paymentMethod),
        clearSchedule: true,
        clearError: true,
        clearCreated: true,
      ),
    );
  }

  void closeRenewFlow() {
    var queue = state.queue;
    final manualId = _manualRenewBookingId;
    if (manualId != null) {
      queue = _without(queue, manualId);
      _manualRenewBookingId = null;
    }

    _emitSafe(
      state.copyWith(
        queue: queue,
        isFlowOpen: false,
        clearSchedule: true,
        clearCreated: true,
      ),
    );
  }

  void selectStartDate(DateTime date) {
    final current = state.current;
    if (current == null) return;

    final start = SessionScheduleHelper.dateOnly(date);
    final end = SessionScheduleHelper.subscriptionEndDate(start);
    final sessionDates = SessionScheduleHelper.generateSessionDates(
      startDate: start,
      selectedDays: current.selectedDays,
    );

    if (sessionDates.isEmpty) {
      _emitSafe(
        state.copyWith(
          errorMessage:
              'No sessions fall within this month for the selected start date.',
          clearSchedule: true,
        ),
      );
      return;
    }

    _emitSafe(
      state.copyWith(
        startDate: start,
        endDate: end,
        sessionDates: sessionDates,
        clearError: true,
      ),
    );
  }

  void selectPaymentMethod(PaymentMethod method) {
    _emitSafe(state.copyWith(paymentMethod: method, clearError: true));
  }

  Future<void> submit() async {
    final current = state.current;
    final start = state.startDate;
    final end = state.endDate;
    if (current == null || start == null || end == null || state.isSubmitting) {
      return;
    }

    _emitSafe(
      state.copyWith(isSubmitting: true, clearError: true, clearCreated: true),
    );

    try {
      final method = state.paymentMethod;
      final reference = method == PaymentMethod.instapay
          ? PaymentReferenceHelper.generate(
              coachName: current.coachName,
              sessionTime: current.selectedTime ?? '',
              startDate: start,
            )
          : null;

      final created = await _repository.renewExpiredBooking(
        sourceBookingId: current.bookingId,
        startDate: start,
        paymentMethod: method.apiValue,
        paymentReference: reference,
      );

      MemberDataSync.afterBookingMutationUnawaited();

      if (_manualRenewBookingId == current.bookingId) {
        _manualRenewBookingId = null;
      }

      _emitSafe(
        state.copyWith(
          isSubmitting: false,
          isFlowOpen: false,
          queue: _without(state.queue, current.bookingId),
          created: created.copyWith(
            coachName: current.coachName,
            paymentReference: created.paymentReference ?? reference,
          ),
          createdStartDate: start,
          createdEndDate: end,
          createdSessionTime: current.selectedTime,
          clearSchedule: true,
        ),
      );
    } catch (error) {
      _emitSafe(
        state.copyWith(
          isSubmitting: false,
          errorMessage: _message(error),
        ),
      );
    }
  }

  void clearCreated() {
    _emitSafe(state.copyWith(clearCreated: true));
  }

  static List<BookingHistoryModel> _without(
    List<BookingHistoryModel> queue,
    String bookingId,
  ) {
    return queue.where((item) => item.bookingId != bookingId).toList();
  }

  static PaymentMethod _methodFrom(String? raw) {
    final value = raw?.toLowerCase().trim();
    if (value == PaymentMethod.instapay.name) return PaymentMethod.instapay;
    return PaymentMethod.cash;
  }

  static String _message(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

class BookingRenewState extends Equatable {
  const BookingRenewState({
    this.isLoading = false,
    this.isDismissing = false,
    this.isSubmitting = false,
    this.isFlowOpen = false,
    this.queue = const [],
    this.startDate,
    this.endDate,
    this.sessionDates = const [],
    this.paymentMethod = PaymentMethod.cash,
    this.created,
    this.createdStartDate,
    this.createdEndDate,
    this.createdSessionTime,
    this.errorMessage,
  });

  const BookingRenewState.initial()
      : isLoading = false,
        isDismissing = false,
        isSubmitting = false,
        isFlowOpen = false,
        queue = const [],
        startDate = null,
        endDate = null,
        sessionDates = const [],
        paymentMethod = PaymentMethod.cash,
        created = null,
        createdStartDate = null,
        createdEndDate = null,
        createdSessionTime = null,
        errorMessage = null;

  final bool isLoading;
  final bool isDismissing;
  final bool isSubmitting;
  final bool isFlowOpen;
  final List<BookingHistoryModel> queue;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<DateTime> sessionDates;
  final PaymentMethod paymentMethod;
  final BookingModel? created;
  final DateTime? createdStartDate;
  final DateTime? createdEndDate;
  final String? createdSessionTime;
  final String? errorMessage;

  BookingHistoryModel? get current => queue.isEmpty ? null : queue.first;

  bool get hasPrompt => current != null && !isFlowOpen;

  bool get canSubmit =>
      current != null && startDate != null && sessionDates.isNotEmpty;

  BookingRenewState copyWith({
    bool? isLoading,
    bool? isDismissing,
    bool? isSubmitting,
    bool? isFlowOpen,
    List<BookingHistoryModel>? queue,
    DateTime? startDate,
    DateTime? endDate,
    List<DateTime>? sessionDates,
    PaymentMethod? paymentMethod,
    BookingModel? created,
    DateTime? createdStartDate,
    DateTime? createdEndDate,
    String? createdSessionTime,
    String? errorMessage,
    bool clearError = false,
    bool clearSchedule = false,
    bool clearCreated = false,
  }) {
    return BookingRenewState(
      isLoading: isLoading ?? this.isLoading,
      isDismissing: isDismissing ?? this.isDismissing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isFlowOpen: isFlowOpen ?? this.isFlowOpen,
      queue: queue ?? this.queue,
      startDate: clearSchedule ? null : (startDate ?? this.startDate),
      endDate: clearSchedule ? null : (endDate ?? this.endDate),
      sessionDates:
          clearSchedule ? const [] : (sessionDates ?? this.sessionDates),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      created: clearCreated ? null : (created ?? this.created),
      createdStartDate:
          clearCreated ? null : (createdStartDate ?? this.createdStartDate),
      createdEndDate:
          clearCreated ? null : (createdEndDate ?? this.createdEndDate),
      createdSessionTime:
          clearCreated ? null : (createdSessionTime ?? this.createdSessionTime),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isDismissing,
        isSubmitting,
        isFlowOpen,
        queue,
        startDate,
        endDate,
        sessionDates,
        paymentMethod,
        created?.id,
        createdStartDate,
        createdEndDate,
        createdSessionTime,
        errorMessage,
      ];
}
