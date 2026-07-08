import 'package:equatable/equatable.dart';

abstract class BookingDetailState extends Equatable {
  const BookingDetailState();

  @override
  List<Object?> get props => [];
}

class BookingDetailInitial extends BookingDetailState {
  const BookingDetailInitial();
}

class BookingDetailLoading extends BookingDetailState {
  const BookingDetailLoading();
}

class BookingDetailSuccess extends BookingDetailState {
  final String message;

  const BookingDetailSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class BookingDetailError extends BookingDetailState {
  final String message;

  const BookingDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
