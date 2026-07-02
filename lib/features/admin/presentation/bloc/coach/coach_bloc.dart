import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/coach/coach_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/coach/coach_state.dart';

class CoachBloc extends Bloc<CoachEvent, CoachState> {
  final CoachRepository repository;
  StreamSubscription? _subscription;

  CoachBloc({required this.repository}) : super(const CoachInitial()) {
    on<CoachStarted>(_onStarted);
    on<RefreshCoaches>(_onRefresh);
    on<CoachesStreamUpdated>(_onStreamUpdated);
    on<CoachesStreamFailed>(_onStreamFailed);
  }

  Future<void> _onStarted(
    CoachStarted event,
    Emitter<CoachState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = repository.stream.listen(
      (coaches) => add(CoachesStreamUpdated(coaches)),
      onError: (Object error) {
        add(CoachesStreamFailed(error.toString()));
      },
    );
    add(const RefreshCoaches());
  }

  Future<void> _onRefresh(
    RefreshCoaches event,
    Emitter<CoachState> emit,
  ) async {
    if (state is! CoachLoaded) {
      emit(const CoachLoading());
    }

    try {
      if (event.force) {
        repository.invalidateStreamCache();
      }
      final coaches = await repository.refresh();
      emit(CoachLoaded(coaches));
    } catch (e) {
      emit(CoachError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  void _onStreamUpdated(
    CoachesStreamUpdated event,
    Emitter<CoachState> emit,
  ) {
    emit(CoachLoaded(event.coaches));
  }

  void _onStreamFailed(
    CoachesStreamFailed event,
    Emitter<CoachState> emit,
  ) {
    emit(CoachError(event.message.replaceFirst('Exception: ', '')));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
