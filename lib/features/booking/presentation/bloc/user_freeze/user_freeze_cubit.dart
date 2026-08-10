import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/session_schedule_helper.dart';
import 'package:prince_academy/core/services/member_data_sync.dart';
import 'package:prince_academy/features/admin/data/models/session_detail_model.dart';
import 'package:prince_academy/features/admin/data/repositories/admin_dashboard_repository.dart';
import 'package:prince_academy/features/booking/data/models/booking_freeze_model.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_freeze_repository.dart';
import 'package:prince_academy/features/sessions/data/repositories/sessions_repository.dart';

class UserFreezeCubit extends Cubit<UserFreezeState> {
  UserFreezeCubit(this._freezeRepo, this._sessionsRepo)
      : super(const UserFreezeState.initial());

  final BookingFreezeRepository _freezeRepo;
  final SessionsRepository _sessionsRepo;
  StreamSubscription<List<SessionDetail>>? _sessionsSub;

  Future<void> load({
    required String bookingId,
    required FreezeActor actor,
  }) async {
    emit(
      state.copyWith(
        bookingId: bookingId,
        actor: actor,
        clearError: true,
        clearSuccess: true,
      ),
    );

    // Cache-first paint (member reuses SessionsRepository; admin uses freeze TTL).
    final cachedSessions = actor == FreezeActor.member
        ? _sessionsRepo.getCachedBookingSessions(bookingId)
        : _freezeRepo.getCachedBookingSessions(bookingId);
    final cachedContext = _freezeRepo.getCachedFreezeContext(bookingId);
    final hasCache = cachedSessions != null || cachedContext != null;

    if (hasCache) {
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: true,
          subscriptionEnd: cachedContext?.subscriptionEnd,
          sessions: _selectable(cachedSessions ?? const []),
          selectedKeys: const {},
          clearError: true,
        ),
      );
    } else {
      emit(state.copyWith(isLoading: true, clearError: true));
    }

    await _sessionsSub?.cancel();
    _sessionsSub = null;
    if (actor == FreezeActor.member) {
      _sessionsSub = _sessionsRepo.watchBookingSessions(bookingId).listen(
        (sessions) {
          emit(
            state.copyWith(
              isLoading: false,
              isRefreshing: false,
              sessions: _selectable(sessions),
            ),
          );
        },
        onError: (Object error) {
          if (state.sessions.isEmpty) {
            emit(
              state.copyWith(
                isLoading: false,
                isRefreshing: false,
                errorMessage: _message(error),
              ),
            );
          }
        },
      );
    }

    try {
      BookingFreezeContext? context;
      List<SessionDetail> sessions = const [];
      Object? loadError;

      try {
        context = await _freezeRepo.getFreezeContext(bookingId, force: true);
      } catch (e) {
        loadError = e;
      }

      try {
        if (actor == FreezeActor.member) {
          sessions = await _sessionsRepo.refreshBookingSessions(
            bookingId,
            force: true,
          );
        } else {
          sessions = await _freezeRepo.getBookingSessions(
            bookingId,
            force: true,
          );
        }
      } catch (e) {
        loadError ??= e;
      }

      final selectable = _selectable(sessions);

      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          subscriptionEnd: context?.subscriptionEnd,
          sessions: selectable,
          selectedKeys: const {},
          errorMessage: selectable.isEmpty && loadError != null
              ? _message(loadError)
              : null,
          clearError: selectable.isNotEmpty || loadError == null,
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

  void toggleDate(DateTime date) {
    final key = _dateKey(date);
    final next = Set<String>.from(state.selectedKeys);
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    emit(state.copyWith(selectedKeys: next, clearError: true));
  }

  Future<void> submit() async {
    if (state.bookingId == null || state.selectedDates.isEmpty) return;
    if (state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true));

    try {
      if (state.actor == FreezeActor.admin) {
        await _freezeRepo.applyFreeze(
          bookingId: state.bookingId!,
          sessionDates: state.selectedDates,
        );
      } else {
        await _freezeRepo.requestFreeze(
          bookingId: state.bookingId!,
          sessionDates: state.selectedDates,
        );
      }

      MemberDataSync.afterBookingMutationUnawaited();
      unawaited(_refreshDashboardQuietly());

      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage: state.actor == FreezeActor.admin
              ? 'Sessions frozen successfully'
              : 'Freeze request sent',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: _message(error),
        ),
      );
    }
  }

  static List<SessionDetail> _selectable(List<SessionDetail> sessions) {
    return sessions
        .where((s) => !s.isAttended && s.status.toLowerCase() != 'frozen')
        .where((s) {
          final st = s.status.toLowerCase();
          return st == 'missed' || st == 'today' || st == 'upcoming';
        })
        .toList();
  }

  static String _dateKey(DateTime date) {
    final d = SessionScheduleHelper.dateOnly(date);
    return '${d.year}-${d.month}-${d.day}';
  }

  static String _message(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }

  static Future<void> _refreshDashboardQuietly() async {
    try {
      await sl<AdminDashboardRepository>().refresh();
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    await _sessionsSub?.cancel();
    return super.close();
  }
}

class UserFreezeState extends Equatable {
  const UserFreezeState({
    this.bookingId,
    this.actor = FreezeActor.member,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isSubmitting = false,
    this.sessions = const [],
    this.selectedKeys = const {},
    this.subscriptionEnd,
    this.errorMessage,
    this.successMessage,
  });

  const UserFreezeState.initial()
      : bookingId = null,
        actor = FreezeActor.member,
        isLoading = true,
        isRefreshing = false,
        isSubmitting = false,
        sessions = const [],
        selectedKeys = const {},
        subscriptionEnd = null,
        errorMessage = null,
        successMessage = null;

  final String? bookingId;
  final FreezeActor actor;
  final bool isLoading;
  final bool isRefreshing;
  final bool isSubmitting;
  final List<SessionDetail> sessions;
  final Set<String> selectedKeys;
  final DateTime? subscriptionEnd;
  final String? errorMessage;
  final String? successMessage;

  List<DateTime> get selectedDates {
    final out = <DateTime>[];
    for (final s in sessions) {
      final key =
          '${s.sessionDate.year}-${s.sessionDate.month}-${s.sessionDate.day}';
      if (selectedKeys.contains(key)) {
        out.add(SessionScheduleHelper.dateOnly(s.sessionDate));
      }
    }
    out.sort();
    return out;
  }

  int get selectedCount => selectedKeys.length;

  DateTime? get previewNewExpiry {
    if (subscriptionEnd == null || selectedCount == 0) return null;
    final end = SessionScheduleHelper.dateOnly(subscriptionEnd!);
    return end.add(Duration(days: selectedCount));
  }

  bool get canSubmit => selectedCount > 0 && !isSubmitting && !isLoading;

  String get confirmLabel =>
      actor == FreezeActor.admin ? 'Confirm Freeze' : 'Request Freeze';

  UserFreezeState copyWith({
    String? bookingId,
    FreezeActor? actor,
    bool? isLoading,
    bool? isRefreshing,
    bool? isSubmitting,
    List<SessionDetail>? sessions,
    Set<String>? selectedKeys,
    DateTime? subscriptionEnd,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return UserFreezeState(
      bookingId: bookingId ?? this.bookingId,
      actor: actor ?? this.actor,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      sessions: sessions ?? this.sessions,
      selectedKeys: selectedKeys ?? this.selectedKeys,
      subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        actor,
        isLoading,
        isRefreshing,
        isSubmitting,
        sessions,
        selectedKeys,
        subscriptionEnd,
        errorMessage,
        successMessage,
      ];
}
