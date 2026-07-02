import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/helpers/image_resize_helper.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_home/admin_home_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_home/admin_home_state.dart';

class AdminHomeBloc extends Bloc<AdminHomeEvent, AdminHomeState> {
  final CoachRepository repository;

  AdminHomeBloc({required this.repository}) : super(const AdminHomeState()) {
    on<AdminHomeStarted>(_onStarted);
    on<RefreshCoaches>(_onRefreshCoaches);
    on<RefreshSessions>(_onRefreshSessions);
    on<AddCoachSubmitted>(_onAddCoach);
    on<SaveSessionSubmitted>(_onSaveSession);
    on<DeleteCoachSubmitted>(_onDeleteCoach);
    on<DeleteSessionScheduleSubmitted>(_onDeleteSessionSchedule);
    on<ClearAdminHomeMessage>(_onClearMessage);
  }

  Future<void> _onStarted(
    AdminHomeStarted event,
    Emitter<AdminHomeState> emit,
  ) async {
    add(const RefreshCoaches());
    add(const RefreshSessions());
  }

  Future<void> _onRefreshCoaches(
    RefreshCoaches event,
    Emitter<AdminHomeState> emit,
  ) async {
    if (state.coaches.isEmpty) {
      emit(state.copyWith(isLoadingCoaches: true));
    }

    try {
      final coaches =
          await repository.fetchCoaches(force: event.force);
      emit(state.copyWith(
        coaches: coaches,
        isLoadingCoaches: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingCoaches: false,
        message: 'Failed to load coaches: $e',
        messageType: AdminHomeMessageType.error,
      ));
    }
  }

  Future<void> _onRefreshSessions(
    RefreshSessions event,
    Emitter<AdminHomeState> emit,
  ) async {
    emit(state.copyWith(
      isLoadingSessions: true,
      clearSessionsError: true,
    ));

    try {
      final sessions = await repository.getAllSessionsWithCoach();
      emit(state.copyWith(
        sessions: sessions,
        isLoadingSessions: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingSessions: false,
        sessionsError: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onAddCoach(
    AddCoachSubmitted event,
    Emitter<AdminHomeState> emit,
  ) async {
    emit(state.copyWith(isAddingCoach: true));

    try {
      String? photoUrl;
      if (event.imagePath != null) {
        final original = File(event.imagePath!);
        final resized = await ImageResizeHelper.resizeCoachPhoto(original);
        final fileName = resized.path.split(Platform.pathSeparator).last;
        photoUrl = await repository.uploadCoachPhoto(resized, fileName);
      }

      await repository.addCoach(
        name: event.name,
        specialty: event.specialty,
        photoUrl: photoUrl,
      );

      repository.invalidateCaches();
      await repository.refresh();
      add(const RefreshCoaches(force: true));

      emit(state.copyWith(
        isAddingCoach: false,
        message: 'Coach added successfully!',
        messageType: AdminHomeMessageType.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        isAddingCoach: false,
        message: 'Failed to add coach: $e',
        messageType: AdminHomeMessageType.error,
      ));
    }
  }

  Future<void> _onSaveSession(
    SaveSessionSubmitted event,
    Emitter<AdminHomeState> emit,
  ) async {
    emit(state.copyWith(isSavingSession: true));

    try {
      await repository.upsertSession(event.draft);
      add(const RefreshSessions());
      emit(state.copyWith(
        isSavingSession: false,
        message: 'Session saved successfully!',
        messageType: AdminHomeMessageType.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSavingSession: false,
        message: 'Failed to save session: $e',
        messageType: AdminHomeMessageType.error,
      ));
    }
  }

  Future<void> _onDeleteCoach(
    DeleteCoachSubmitted event,
    Emitter<AdminHomeState> emit,
  ) async {
    try {
      await repository.deleteCoach(event.coachId);
      final coaches =
          state.coaches.where((c) => c.id != event.coachId).toList();
      final sessions =
          state.sessions.where((s) => s.coachId != event.coachId).toList();
      repository.invalidateCaches();
      emit(state.copyWith(
        coaches: coaches,
        sessions: sessions,
        message: 'Coach and their sessions deleted',
        messageType: AdminHomeMessageType.delete,
      ));
    } catch (e) {
      emit(state.copyWith(
        message: 'Failed to delete coach: $e',
        messageType: AdminHomeMessageType.error,
      ));
      add(const RefreshCoaches(force: true));
      add(const RefreshSessions());
    }
  }

  Future<void> _onDeleteSessionSchedule(
    DeleteSessionScheduleSubmitted event,
    Emitter<AdminHomeState> emit,
  ) async {
    try {
      for (final id in event.sessionIds) {
        await repository.deleteSession(id);
      }
      add(const RefreshSessions());
      emit(state.copyWith(
        message: 'Session schedule deleted',
        messageType: AdminHomeMessageType.delete,
      ));
    } catch (e) {
      emit(state.copyWith(
        message: 'Failed to delete session schedule: $e',
        messageType: AdminHomeMessageType.error,
      ));
      add(const RefreshSessions());
    }
  }

  void _onClearMessage(
    ClearAdminHomeMessage event,
    Emitter<AdminHomeState> emit,
  ) {
    emit(state.copyWith(clearMessage: true));
  }
}
