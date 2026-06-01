
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthUserSignUp extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String phone;
  AuthUserSignUp(this.email, this.password, this.fullName, this.phone);

  @override
  List<Object?> get props => [email, password, fullName, phone];
}

class AuthUserSignIn extends AuthEvent {
  final String email;
  final String password;
  AuthUserSignIn(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthAdminSignIn extends AuthEvent {
  final String email;
  final String password;
  AuthAdminSignIn(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthSignOut extends AuthEvent {}