import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/models/admin_dashboard_model.dart';
import 'package:prince_academy/features/admin/data/repositories/admin_dashboard_repository.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit({required AdminDashboardRepository repository})
      : _repository = repository,
        super(const AdminDashboardState.initial());

  final AdminDashboardRepository _repository;
  StreamSubscription<AdminDashboardData>? _subscription;

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

  static String _errorMessage(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class AdminDashboardState extends Equatable {
  const AdminDashboardState({
    this.data,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  const AdminDashboardState.initial()
      : data = null,
        isInitialLoading = true,
        isRefreshing = false,
        errorMessage = null;

  final AdminDashboardData? data;
  final bool isInitialLoading;
  final bool isRefreshing;
  final String? errorMessage;

  AdminDashboardState copyWith({
    AdminDashboardData? data,
    bool? isInitialLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminDashboardState(
      data: data ?? this.data,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        data,
        isInitialLoading,
        isRefreshing,
        errorMessage,
      ];
}
