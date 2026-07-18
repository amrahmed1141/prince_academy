import 'package:equatable/equatable.dart';

import 'package:prince_academy/features/notifications/data/models/app_notification.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  const NotificationLoaded({
    required this.notifications,
    this.isRefreshing = false,
  });

  final List<AppNotification> notifications;
  final bool isRefreshing;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationLoaded copyWith({
    List<AppNotification>? notifications,
    bool? isRefreshing,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [notifications, isRefreshing, unreadCount];
}

class NotificationError extends NotificationState {
  const NotificationError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
