import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/booking/data/models/booking_freeze_model.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_freeze_repository.dart';

class MyFreezeRequestsCubit extends Cubit<MyFreezeRequestsState> {
  MyFreezeRequestsCubit(this._repository)
      : super(const MyFreezeRequestsState.initial());

  final BookingFreezeRepository _repository;
  StreamSubscription<List<MemberFreezeRequest>>? _subscription;

  Future<void> load() async {
    _subscription ??= _repository.myFreezeRequestsStream.listen(
      (items) {
        emit(
          MyFreezeRequestsState(
            items: items,
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

    final hasData = state.items.isNotEmpty;
    emit(
      state.copyWith(
        isLoading: !hasData,
        isRefreshing: hasData,
        clearError: true,
      ),
    );

    try {
      await _repository.getMyFreezeRequests();
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

  static String _message(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

class MyFreezeRequestsState extends Equatable {
  const MyFreezeRequestsState({
    this.items = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  const MyFreezeRequestsState.initial()
      : items = const [],
        isLoading = true,
        isRefreshing = false,
        errorMessage = null;

  final List<MemberFreezeRequest> items;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  List<MemberFreezeRequest> get pending =>
      items.where((e) => e.isPending).toList();

  List<MemberFreezeRequest> get approved =>
      items.where((e) => e.isApproved).toList();

  List<MemberFreezeRequest> get rejected =>
      items.where((e) => e.isRejected).toList();

  MyFreezeRequestsState copyWith({
    List<MemberFreezeRequest>? items,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyFreezeRequestsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [items, isLoading, isRefreshing, errorMessage];
}
