import 'package:english_reader_app/core/errors/app_exception.dart';
import 'package:english_reader_app/features/auth/domain/entities/auth_session.dart';
import 'package:english_reader_app/features/auth/domain/entities/auth_user.dart';
import 'package:english_reader_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:english_reader_app/features/auth/presentation/cubit/account_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('El registro expone el mensaje de confirmación de la API', () async {
    final cubit = AccountCubit(_FakeAuthRepository());
    addTearDown(cubit.close);

    await cubit.register(
      email: 'nuevo@correo.com',
      password: 'Cliente123*',
      firstName: 'Ana',
      lastName: 'García',
      phone: '',
    );

    expect(cubit.state.status, AccountStatus.success);
    expect(cubit.state.message, 'Revisa tu correo para confirmar la cuenta.');
  });

  test(
    'La recuperación traduce el error de la API a un mensaje legible',
    () async {
      final cubit = AccountCubit(_FakeAuthRepository(fails: true));
      addTearDown(cubit.close);

      await cubit.requestPasswordReset('nuevo@correo.com');

      expect(cubit.state.status, AccountStatus.failure);
      expect(cubit.state.message, 'Demasiadas solicitudes.');
    },
  );

  test('El cambio de contraseña envía el token recibido por correo', () async {
    final repository = _FakeAuthRepository();
    final cubit = AccountCubit(repository);
    addTearDown(cubit.close);

    await cubit.resetPassword(token: 'token-123', password: 'Cliente123*');

    expect(repository.lastToken, 'token-123');
    expect(cubit.state.status, AccountStatus.success);
  });
}

/// Repositorio fake para ejercitar los flujos de cuenta sin API real.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.fails = false});

  final bool fails;
  String? lastToken;

  @override
  Future<String> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    if (fails) throw const AppException(message: 'Correo ya registrado.');
    return 'Revisa tu correo para confirmar la cuenta.';
  }

  @override
  Future<String> requestPasswordReset(String email) async {
    if (fails) throw const AppException(message: 'Demasiadas solicitudes.');
    return 'Correo enviado.';
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String password,
  }) async {
    lastToken = token;
    if (fails) throw const AppException(message: 'Token inválido.');
    return 'Contraseña actualizada.';
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser?> verifySession() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> hasLocalSession() async => false;
}
