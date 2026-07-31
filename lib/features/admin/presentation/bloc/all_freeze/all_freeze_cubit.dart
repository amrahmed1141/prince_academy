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

  Future<void> load() async {
    final hasData =
        state.pending.isNotEmpty || state.active.isNotEmpty;
    emit(
      state.copyWith(
        isLoading: !hasData,
        isRefreshing: hasData,
        clearError: true,
      ),
    );

    try {
      final results = await Future.wait([
        _repository.getPendingRequests(),
        _repository.getActiveFreezes(),
      ]);
      emit(
        AllFreezeState(
          pending: results[0] as List<PendingFreezeRequest>,
          active: results[1] as List<ActiveBookingFreeze>,
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

  Future<void> refresh() => load();

  Future<void> approve(String freezeId) => _review(freezeId, true);

  Future<void> reject(String freezeId) => _review(freezeId, false);

  Future<void> _review(String freezeId, bool approve) async {
    emit(state.copyWith(busyFreezeId: freezeId, clearError: true));
    try {
      await _repository.reviewFreeze(freezeId: freezeId, approve: approve);
      unawaited(_refreshDashboardQuietly());
      await load();
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
