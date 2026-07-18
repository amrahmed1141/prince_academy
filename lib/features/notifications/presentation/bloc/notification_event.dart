import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Start watching the feed (initial load + realtime).
class NotificationsStarted extends NotificationEvent {
  const NotificationsStarted();
}

class NotificationsRefreshed extends NotificationEvent {
  const NotificationsRefreshed({this.force = true});

  final bool force;

  @override
  List<Object?> get props => [force];
}

class NotificationMarkedRead extends NotificationEvent {
  const NotificationMarkedRead(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class NotificationsMarkAllRead extends NotificationEvent {
  const NotificationsMarkAllRead();
}
