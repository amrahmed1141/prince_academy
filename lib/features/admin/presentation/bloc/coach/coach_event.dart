import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';

abstract class CoachEvent extends Equatable {
  const CoachEvent();

  @override
  List<Object?> get props => [];
}

class CoachStarted extends CoachEvent {
  const CoachStarted();
}

class RefreshCoaches extends CoachEvent {
  const RefreshCoaches({this.force = false});

  final bool force;

  @override
  List<Object?> get props => [force];
}

class CoachesStreamUpdated extends CoachEvent {
  const CoachesStreamUpdated(this.coaches);

  final List<CoachModel> coaches;

  @override
  List<Object?> get props => [coaches];
}

class CoachesStreamFailed extends CoachEvent {
  const CoachesStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
