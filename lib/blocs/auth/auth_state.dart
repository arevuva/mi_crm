part of 'auth_bloc.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final AppUser user;

  Authenticated(this.user);
}

class Unauthenticated extends AuthState {
  final String? message;

  Unauthenticated({this.message});
}
