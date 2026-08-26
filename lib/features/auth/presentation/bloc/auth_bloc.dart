import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_messages.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(const AuthState.initial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);
  }

  final AuthRepository _authRepository;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.checking));
    try {
      final user = await _authRepository.verifySession();
      if (user == null) {
        emit(const AuthState.unauthenticated());
        return;
      }
      emit(AuthState.authenticated(user));
    } catch (error) {
      final exception = AppException.fromUnknown(error);
      emit(
        AuthState.unauthenticated(
          message: exception.isSessionInvalidated
              ? AppMessages.sessionInvalidated
              : AppMessages.sessionExpired,
        ),
      );
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.checking, message: null));
    try {
      final session = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthState.authenticated(session.user));
    } catch (error) {
      final exception = AppException.fromUnknown(error);
      emit(AuthState.unauthenticated(message: exception.message));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthState.unauthenticated());
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(AuthState.unauthenticated(message: event.message));
  }
}
