import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/repositories/finance_repository.dart';

class FinanceCubit extends Cubit<FinanceState> {
  FinanceCubit({required FinanceRepository repository})
      : _repository = repository,
        super(const FinanceState.initial());

  final FinanceRepository _repository;
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
  });

  const FinanceState.initial()
      : data = null,
        isInitialLoading = true,
        isRefreshing = false,
        errorMessage = null;

  final FinanceDashboardData? data;
  final bool isInitialLoading;
  final bool isRefreshing;
  final String? errorMessage;

  FinanceState copyWith({
    FinanceDashboardData? data,
    bool? isInitialLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FinanceState(
      data: data ?? this.data,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [data, isInitialLoading, isRefreshing, errorMessage];
}
