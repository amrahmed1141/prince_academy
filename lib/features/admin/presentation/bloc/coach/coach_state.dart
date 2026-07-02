import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';

abstract class CoachState extends Equatable {
  const CoachState();

  @override
  List<Object?> get props => [];
}

class CoachInitial extends CoachState {
  const CoachInitial();
}

class CoachLoading extends CoachState {
  const CoachLoading();
}

class CoachLoaded extends CoachState {
  const CoachLoaded(this.coaches);

  final List<CoachModel> coaches;

  @override
  List<Object?> get props => [coaches];
}

class CoachError extends CoachState {
  const CoachError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
