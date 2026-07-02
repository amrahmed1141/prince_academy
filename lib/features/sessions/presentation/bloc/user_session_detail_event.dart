import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/session_detail_model.dart';

abstract class UserSessionDetailEvent extends Equatable {
  const UserSessionDetailEvent();

  @override
  List<Object?> get props => [];
}

class UserSessionDetailStarted extends UserSessionDetailEvent {
  final String bookingId;

  const UserSessionDetailStarted(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class RefreshUserSessionDetail extends UserSessionDetailEvent {
  final String bookingId;

  const RefreshUserSessionDetail(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class UserSessionDetailDataUpdated extends UserSessionDetailEvent {
  final List<SessionDetail> sessions;

  const UserSessionDetailDataUpdated(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

class UserSessionDetailDataFailed extends UserSessionDetailEvent {
  final String message;

  const UserSessionDetailDataFailed(this.message);

  @override
  List<Object?> get props => [message];
}
