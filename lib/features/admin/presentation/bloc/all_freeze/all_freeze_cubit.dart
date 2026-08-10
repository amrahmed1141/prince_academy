import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/admin/data/repositories/admin_dashboard_repository.dart';
import 'package:prince_academy/features/booking/data/models/booking_freeze_model.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_freeze_repository.dart';

class AllFreezeCubit extends Cubit<AllFreezeState> {
  AllFreezeCubit(this._repository) : super(const AllFreezeState.initial());

  final BookingFreezeRepository _repository;
  StreamSubscription<AdminFreezeLists>? _subscription;

  Future<void> load() async {
    final cached = _repository.cachedValue;
    final hasData = state.pending.isNotEmpty ||
        state.active.isNotEmpty ||
        cached != null;

    if (cached != null &&
        state.pending.isEmpty &&
        state.active.isEmpty) {
      emit(
        state.copyWith(
          pending: cached.pending,
          active: cached.active,
          isLoading: false,
          isRefreshing: true,
          clearError: true,
        ),
      );
    } else if (!hasData) {
      emit(state.copyWith(isLoading: true, clearError: true));
    } else {
      emit(state.copyWith(isRefreshing: true, clearError: true));
    }

    await _subscription?.cancel();
    _repository.ensureAdminListsRealtime();
    _subscription = _repository.stream.listen(
      (lists) {
        emit(
          AllFreezeState(
            pending: lists.pending,
            active: lists.active,
            isLoading: false,
            isRefreshing: false,
          ),
        );
      },
      onError: (Object error) {
        emit(
          state.copyWith(
            isLoading: false,
            isRefreshing: false,
            errorMessage: _message(error),
          ),
        );
      },
    );

    try {
      final lists = await _repository.getAdminLists(force: false);
      emit(
        AllFreezeState(
          pending: lists.pending,
          active: lists.active,
          isLoading: false,
          isRefreshing: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: _message(error),
        ),
      );
    }
  }

  Future<void> refresh() async {
    final hasData = state.pending.isNotEmpty || state.active.isNotEmpty;
    if (!hasData) return load();

    emit(state.copyWith(isRefreshing: true, clearError: true));
    try {
      final lists = await _repository.getAdminLists(force: true);
      emit(
        AllFreezeState(
          pending: lists.pending,
          active: lists.active,
          isLoading: false,
          isRefreshing: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: _message(error),
        ),
      );
    }
  }

  Future<void> approve(String freezeId) => _review(freezeId, true);

  Future<void> reject(String freezeId) => _review(freezeId, false);

  Future<void> _review(String freezeId, bool approve) async {
    emit(state.copyWith(busyFreezeId: freezeId, clearError: true));
    try {
      await _repository.reviewFreeze(freezeId: freezeId, approve: approve);
      unawaited(_refreshDashboardQuietly());
      // Realtime / reviewInvalidate already refresh the stream; clear busy.
      emit(state.copyWith(clearBusy: true));
    } catch (error) {
      emit(
        state.copyWith(
          clearBusy: true,
          errorMessage: _message(error),
        ),
      );
    }
  }

  static Future<void> _refreshDashboardQuietly() async {
    try {
      await sl<AdminDashboardRepository>().refresh();
    } catch (_) {}
  }

  static String _message(Object error) {
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

class AllFreezeState extends Equatable {
  const AllFreezeState({
    this.pending = const [],
    this.active = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.busyFreezeId,
    this.errorMessage,
  });

  const AllFreezeState.initial()
      : pending = const [],
        active = const [],
        isLoading = true,
        isRefreshing = false,
        busyFreezeId = null,
        errorMessage = null;

  final List<PendingFreezeRequest> pending;
  final List<ActiveBookingFreeze> active;
  final bool isLoading;
  final bool isRefreshing;
  final String? busyFreezeId;
  final String? errorMessage;

  AllFreezeState copyWith({
    List<PendingFreezeRequest>? pending,
    List<ActiveBookingFreeze>? active,
    bool? isLoading,
    bool? isRefreshing,
    String? busyFreezeId,
    String? errorMessage,
    bool clearError = false,
    bool clearBusy = false,
  }) {
    return AllFreezeState(
      pending: pending ?? this.pending,
      active: active ?? this.active,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      busyFreezeId: clearBusy ? null : (busyFreezeId ?? this.busyFreezeId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        pending,
        active,
        isLoading,
        isRefreshing,
        busyFreezeId,
        errorMessage,
      ];
}
