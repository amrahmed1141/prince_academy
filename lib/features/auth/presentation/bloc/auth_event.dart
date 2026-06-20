import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

@immutable
class SignUpRequested extends AuthEvent {
  final String fullName;
  final String phone;
  final String email;
  final String password;

  const SignUpRequested({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [fullName, phone, email, password];
}

class AuthUserSignIn extends AuthEvent {
  final String email;
  final String password;

  const AuthUserSignIn(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class AuthAdminSignIn extends AuthEvent {
  final String email;
  final String password;

  const AuthAdminSignIn(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class AuthSignOut extends AuthEvent {
  const AuthSignOut();
}
