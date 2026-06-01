import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/auth/data/models/app_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthNoSession extends AuthState {
  const AuthNoSession();
}

class AuthAuthed extends AuthState {
  final UserModel user;
  const AuthAuthed(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}