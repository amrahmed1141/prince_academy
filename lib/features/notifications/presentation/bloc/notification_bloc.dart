import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:prince_academy/core/services/firebase_messaging_service.dart';
import 'package:prince_academy/features/notifications/data/models/app_notification.dart';
import 'package:prince_academy/features/notifications/data/repositories/notification_repository.dart';
import 'package:prince_academy/features/notifications/presentation/bloc/notification_event.dart';
import 'package:prince_academy/features/notifications/presentation/bloc/notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc(this._repository) : super(const NotificationInitial()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationsRefreshed>(_onRefreshed);
    on<NotificationMarkedRead>(_onMarkedRead);
    on<NotificationsMarkAllRead>(_onMarkAllRead);
    on<_NotificationsUpdated>(_onUpdated);
  }

  final NotificationRepository _repository;
  StreamSubscription<List<AppNotification>>? _subscription;
  bool _tokenBound = false;

  Future<void> _onStarted(
    NotificationsStarted event,
    Emitter<NotificationState> emit,
  ) async {
    _bindFcmTokenSaver();
    _ensureRealtimeSubscription();

    final cached = _repository.cachedNotifications;
    if (cached.isNotEmpty) {
      emit(NotificationLoaded(notifications: cached, isRefreshing: true));
    } else {
      emit(const NotificationLoading());
    }

    try {
      final list = await _repository.fetchNotifications(force: true);
      emit(NotificationLoaded(notifications: list));
      // Persist token once we know the user session is active.
      unawaited(FirebaseMessagingService.refreshAndSyncToken());
    } catch (e) {
      if (cached.isNotEmpty) {
        emit(NotificationLoaded(notifications: cached));
      } else {
        emit(NotificationError(
          e.toString().replaceFirst('Exception: ', ''),
        ));
      }
    }
  }

  Future<void> _onRefreshed(
    NotificationsRefreshed event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is NotificationLoaded) {
      emit(current.copyWith(isRefreshing: true));
    } else {
      emit(const NotificationLoading());
    }

    try {
      final list =
          await _repository.fetchNotifications(force: event.force);
      emit(NotificationLoaded(notifications: list));
    } catch (e) {
      if (current is NotificationLoaded) {
        emit(current.copyWith(isRefreshing: false));
      } else {
        emit(NotificationError(
          e.toString().replaceFirst('Exception: ', ''),
        ));
      }
    }
  }

  Future<void> _onMarkedRead(
    NotificationMarkedRead event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is NotificationLoaded) {
      emit(
        current.copyWith(
          notifications: [
            for (final n in current.notifications)
              if (n.id == event.id) n.copyWith(isRead: true) else n,
          ],
        ),
      );
    }

    try {
      await _repository.markAsRead(event.id);
    } catch (_) {
      add(const NotificationsRefreshed());
    }
  }

  Future<void> _onMarkAllRead(
    NotificationsMarkAllRead event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state;
    if (current is NotificationLoaded) {
      emit(
        current.copyWith(
          notifications: [
            for (final n in current.notifications) n.copyWith(isRead: true),
          ],
        ),
      );
    }

    try {
      await _repository.markAllAsRead();
    } catch (_) {
      add(const NotificationsRefreshed());
    }
  }

  void _onUpdated(
    _NotificationsUpdated event,
    Emitter<NotificationState> emit,
  ) {
    emit(NotificationLoaded(notifications: event.notifications));
  }

  void _ensureRealtimeSubscription() {
    _subscription ??= _repository.notificationsStream.listen(
      (list) => add(_NotificationsUpdated(list)),
    );
  }

  void _bindFcmTokenSaver() {
    if (_tokenBound) return;
    _tokenBound = true;
    FirebaseMessagingService.onToken = _repository.saveFcmToken;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class _NotificationsUpdated extends NotificationEvent {
  const _NotificationsUpdated(this.notifications);

  final List<AppNotification> notifications;

  @override
  List<Object?> get props => [notifications];
}
