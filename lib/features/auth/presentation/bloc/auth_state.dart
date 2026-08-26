part of 'auth_bloc.dart';

enum AuthStatus { initial, checking, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({required this.status, this.user, this.message});

  const AuthState.initial()
    : status = AuthStatus.initial,
      user = null,
      message = null;

  const AuthState.unauthenticated({String? message})
    : status = AuthStatus.unauthenticated,
      user = null,
      message = message;

  const AuthState.authenticated(AuthUser user)
    : status = AuthStatus.authenticated,
      user = user,
      message = null;

  final AuthStatus status;
  final AuthUser? user;
  final String? message;

  bool get isLoading => status == AuthStatus.checking;

  AuthState copyWith({AuthStatus? status, AuthUser? user, String? message}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, user, message];
}
