import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/models/coach_with_sessions.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class AllSchedulesCubit extends Cubit<AllSchedulesState> {
  AllSchedulesCubit(this._repository) : super(const AllSchedulesState.initial());

  final CoachRepository _repository;

  Future<void> load({bool force = false}) async {
    final hasData = state.groups.isNotEmpty;
    emit(
      state.copyWith(
        isLoading: !hasData,
        isRefreshing: hasData,
        clearError: true,
      ),
    );

    try {
      final sessions = await _repository.getAllSessionsWithCoach();
      emit(
        AllSchedulesState(
          groups: CoachWithSessions.group(sessions),
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

  Future<void> refresh() => load(force: true);

  Future<void> deleteSchedule(List<String> sessionIds) async {
    try {
      for (final id in sessionIds) {
        await _repository.deleteSession(id);
      }
      await load(force: true);
    } catch (error) {
      emit(state.copyWith(errorMessage: _message(error)));
    }
  }

  static String _message(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }
}

class AllSchedulesState extends Equatable {
  const AllSchedulesState({
    this.groups = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  const AllSchedulesState.initial()
      : groups = const [],
        isLoading = true,
        isRefreshing = false,
        errorMessage = null;

  final List<CoachWithSessions> groups;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  List<CoachSessionModel> get flatSessions =>
      groups.expand((g) => g.schedules).toList();

  AllSchedulesState copyWith({
    List<CoachWithSessions>? groups,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AllSchedulesState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [groups, isLoading, isRefreshing, errorMessage];
}
