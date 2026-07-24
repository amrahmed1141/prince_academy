import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/sessions/data/repositories/sessions_repository.dart';

enum SessionTab { upcoming, history }

abstract class SessionsEvent extends Equatable {
  const SessionsEvent();

  @override
  List<Object?> get props => [];
}

class SessionsStarted extends SessionsEvent {}

class RefreshSessions extends SessionsEvent {
  final bool force;

  const RefreshSessions({this.force = true});

  @override
  List<Object?> get props => [force];
}

class SessionsDataUpdated extends SessionsEvent {
  final SessionsSnapshot snapshot;

  const SessionsDataUpdated(this.snapshot);

  @override
  List<Object?> get props => [snapshot];
}

class SessionsDataFailed extends SessionsEvent {
  final String message;

  const SessionsDataFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class SelectCoach extends SessionsEvent {
  final String? coachId;
  const SelectCoach(this.coachId);

  @override
  List<Object?> get props => [coachId];
}

class SwitchTab extends SessionsEvent {
  final SessionTab tab;
  const SwitchTab(this.tab);

  @override
  List<Object?> get props => [tab];
}

class SelectDate extends SessionsEvent {
  final DateTime date;
  const SelectDate(this.date);

  @override
  List<Object?> get props => [date];
}

class SearchSessions extends SessionsEvent {
  final String query;

  const SearchSessions(this.query);

  @override
  List<Object?> get props => [query];
}
