import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';

abstract class AdminHomeEvent extends Equatable {
  const AdminHomeEvent();

  @override
  List<Object?> get props => [];
}

class AdminHomeStarted extends AdminHomeEvent {
  const AdminHomeStarted();
}

class RefreshCoaches extends AdminHomeEvent {
  final bool force;

  const RefreshCoaches({this.force = false});

  @override
  List<Object?> get props => [force];
}

class RefreshSessions extends AdminHomeEvent {
  const RefreshSessions();
}

class AddCoachSubmitted extends AdminHomeEvent {
  final String name;
  final String specialty;
  final String? imagePath;

  const AddCoachSubmitted({
    required this.name,
    required this.specialty,
    this.imagePath,
  });

  @override
  List<Object?> get props => [name, specialty, imagePath];
}

class SaveSessionSubmitted extends AdminHomeEvent {
  final SessionDraft draft;

  const SaveSessionSubmitted(this.draft);

  @override
  List<Object?> get props => [draft];
}

class DeleteCoachSubmitted extends AdminHomeEvent {
  final String coachId;

  const DeleteCoachSubmitted(this.coachId);

  @override
  List<Object?> get props => [coachId];
}

class DeleteSessionScheduleSubmitted extends AdminHomeEvent {
  final List<String> sessionIds;

  const DeleteSessionScheduleSubmitted(this.sessionIds);

  @override
  List<Object?> get props => [sessionIds];
}

class ClearAdminHomeMessage extends AdminHomeEvent {
  const ClearAdminHomeMessage();
}
