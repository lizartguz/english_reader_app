import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/auth_repository.dart';

enum AccountStatus { initial, submitting, success, failure }

/// Estado de los flujos de cuenta que no cambian la sesión activa.
class AccountState extends Equatable {
  const AccountState({this.status = AccountStatus.initial, this.message});

  final AccountStatus status;
  final String? message;

  bool get isSubmitting => status == AccountStatus.submitting;

  @override
  List<Object?> get props => [status, message];
}

/// Coordina registro y recuperación de contraseña contra la API.
class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._repository) : super(const AccountState());

  final AuthRepository _repository;

  /// Crea la cuenta cliente y expone el mensaje de confirmación de la API.
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) {
    return _run(
      () => _repository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      ),
    );
  }

  /// Pide el correo de recuperación sin revelar si la cuenta existe.
  Future<void> requestPasswordReset(String email) {
    return _run(() => _repository.requestPasswordReset(email));
  }

  /// Define la contraseña nueva con el token recibido por correo.
  Future<void> resetPassword({
    required String token,
    required String password,
  }) {
    return _run(
      () => _repository.resetPassword(token: token, password: password),
    );
  }

  /// Centraliza estados de envío, éxito y error de los tres flujos.
  Future<void> _run(Future<String> Function() action) async {
    emit(const AccountState(status: AccountStatus.submitting));
    try {
      final message = await action();
      emit(AccountState(status: AccountStatus.success, message: message));
    } catch (error) {
      emit(
        AccountState(
          status: AccountStatus.failure,
          message: AppException.fromUnknown(error).message,
        ),
      );
    }
  }
}
