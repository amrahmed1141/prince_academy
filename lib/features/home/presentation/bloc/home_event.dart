import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {
  final bool forceRefresh;

  const LoadHomeData({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class SelectDate extends HomeEvent {
  final DateTime date;

  const SelectDate(this.date);

  @override
  List<Object?> get props => [date];
}
