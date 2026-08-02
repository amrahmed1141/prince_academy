import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/repositories/admin_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/finance_repository.dart';

class FinanceCubit extends Cubit<FinanceState> {
  FinanceCubit({
    required FinanceRepository repository,
    required AdminRepository adminRepository,
  })  : _repository = repository,
        _adminRepository = adminRepository,
        super(const FinanceState.initial());

  final FinanceRepository _repository;
  final AdminRepository _adminRepository;
  StreamSubscription<FinanceDashboardData>? _subscription;

  Future<void> load() async {
    final cached = _repository.cachedValue;
    final hasData = state.data != null || cached != null;

    if (cached != null && state.data == null) {
      emit(
        state.copyWith(
          data: cached,
          isInitialLoading: false,
          isRefreshing: true,
          clearError: true,
        ),
      );
    } else if (!hasData) {
      emit(state.copyWith(isInitialLoading: true, clearError: true));
    } else {
      emit(state.copyWith(isRefreshing: true, clearError: true));
    }

    await _subscription?.cancel();
    _repository.ensureRealtimeSubscription();
    _subscription = _repository.stream.listen(
      (data) {
        emit(
          state.copyWith(
            data: data,
            isInitialLoading: false,
            isRefreshing: false,
            clearError: true,
          ),
        );
      },
      onError: (Object error) {
        emit(
          state.copyWith(
            isInitialLoading: false,
            isRefreshing: false,
            errorMessage: _errorMessage(error),
          ),
        );
      },
    );

    try {
      final data = await _repository.getDashboard(force: false);
      emit(
        state.copyWith(
          data: data,
          isInitialLoading: false,
          isRefreshing: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          errorMessage: _errorMessage(error),
        ),
      );
    }
  }

  Future<void> refresh() async {
    if (state.data == null) {
      return load();
    }
    emit(state.copyWith(isRefreshing: true, clearError: true));
    try {
      final data = await _repository.refresh();
      emit(
        state.copyWith(
          data: data,
          isRefreshing: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: _errorMessage(error),
        ),
      );
    }
  }

  Future<void> verifyPayment(String bookingId) async {
    if (bookingId.isEmpty || state.busyBookingIds.contains(bookingId)) return;

    emit(
      state.copyWith(
        busyBookingIds: {...state.busyBookingIds, bookingId},
        clearMessage: true,
        clearError: true,
      ),
    );

    try {
      await _adminRepository.verifyPayment(bookingId);
      await _repository.refresh();
      emit(
        state.copyWith(
          busyBookingIds: {...state.busyBookingIds}..remove(bookingId),
          successMessage: 'Payment confirmed',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          busyBookingIds: {...state.busyBookingIds}..remove(bookingId),
          errorMessage: _errorMessage(error),
        ),
      );
    }
  }

  Future<void> rejectPayment(String bookingId, String reason) async {
    if (bookingId.isEmpty || state.busyBookingIds.contains(bookingId)) return;

    emit(
      state.copyWith(
        busyBookingIds: {...state.busyBookingIds, bookingId},
        clearMessage: true,
        clearError: true,
      ),
    );

    try {
      await _adminRepository.rejectPayment(bookingId, reason);
      await _repository.refresh();
      emit(
        state.copyWith(
          busyBookingIds: {...state.busyBookingIds}..remove(bookingId),
          successMessage: 'Payment rejected',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          busyBookingIds: {...state.busyBookingIds}..remove(bookingId),
          errorMessage: _errorMessage(error),
        ),
      );
    }
  }

  void clearMessages() {
    if (state.errorMessage == null && state.successMessage == null) return;
    emit(state.copyWith(clearError: true, clearMessage: true));
  }

  String _errorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class FinanceState extends Equatable {
  const FinanceState({
    this.data,
    required this.isInitialLoading,
    required this.isRefreshing,
    this.errorMessage,
    this.successMessage,
    this.busyBookingIds = const {},
  });

  const FinanceState.initial()
      : data = null,
        isInitialLoading = true,
        isRefreshing = false,
        errorMessage = null,
        successMessage = null,
        busyBookingIds = const {};

  final FinanceDashboardData? data;
  final bool isInitialLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final String? successMessage;
  final Set<String> busyBookingIds;

  FinanceState copyWith({
    FinanceDashboardData? data,
    bool? isInitialLoading,
    bool? isRefreshing,
    String? errorMessage,
    String? successMessage,
    Set<String>? busyBookingIds,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return FinanceState(
      data: data ?? this.data,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessage ? null : (successMessage ?? this.successMessage),
      busyBookingIds: busyBookingIds ?? this.busyBookingIds,
    );
  }

  @override
  List<Object?> get props => [
        data,
        isInitialLoading,
        isRefreshing,
        errorMessage,
        successMessage,
        busyBookingIds,
      ];
}
