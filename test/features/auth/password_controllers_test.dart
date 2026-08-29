import 'dart:async';

import 'package:english_reader_app/core/constants/app_keys.dart';
import 'package:english_reader_app/features/auth/domain/entities/auth_session.dart';
import 'package:english_reader_app/features/auth/domain/entities/auth_user.dart';
import 'package:english_reader_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:english_reader_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:english_reader_app/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Las contraseñas no siguen en memoria despues de usarse (FLT-SEC-016).
///
/// El campo de texto es el reflejo directo de su `TextEditingController`, asi
/// que comprobar que quedo vacio comprueba que el controlador se limpio.
void main() {
  testWidgets('la contraseña se limpia al iniciar sesion con exito', (tester) async {
    final bloc = AuthBloc(_FakeAuthRepository());

    await tester.pumpWidget(
      MaterialApp(home: BlocProvider.value(value: bloc, child: const LoginPage())),
    );

    await tester.enterText(find.byKey(AppKeys.loginEmailField), 'lector@test.local');
    await tester.enterText(find.byKey(AppKeys.loginPasswordField), 'Clave123*');

    // Antes de enviar, el campo conserva lo escrito.
    expect(_textoDe(tester, AppKeys.loginPasswordField), 'Clave123*');

    await tester.tap(find.byKey(AppKeys.loginSubmitButton));
    await tester.pump(const Duration(milliseconds: 50));

    // Con la sesion ya iniciada la contraseña no vuelve a hacer falta.
    expect(_textoDe(tester, AppKeys.loginPasswordField), isEmpty);

    unawaited(bloc.close());
  });

  testWidgets('un intento fallido conserva lo escrito', (tester) async {
    // Limpiar tambien aqui obligaria a reescribir la contraseña tras un error
    // de red, que no es lo que se busca.
    final bloc = AuthBloc(_FakeAuthRepository(falla: true));

    await tester.pumpWidget(
      MaterialApp(home: BlocProvider.value(value: bloc, child: const LoginPage())),
    );

    await tester.enterText(find.byKey(AppKeys.loginEmailField), 'lector@test.local');
    await tester.enterText(find.byKey(AppKeys.loginPasswordField), 'Clave123*');
    await tester.tap(find.byKey(AppKeys.loginSubmitButton));
    await tester.pump(const Duration(milliseconds: 50));

    expect(_textoDe(tester, AppKeys.loginPasswordField), 'Clave123*');

    unawaited(bloc.close());
  });

}

String _textoDe(WidgetTester tester, Key clave) {
  return tester.widget<TextFormField>(find.byKey(clave)).controller?.text ?? '';
}

const _user = AuthUser(
  id: 'user-1',
  email: 'lector@test.local',
  firstName: 'Lector',
  lastName: 'Demo',
  fullName: 'Lector Demo',
  status: 'active',
  roles: ['CLIENT'],
  permissions: [],
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.falla = false});

  final bool falla;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (falla) throw Exception('Credenciales invalidas.');

    return AuthSession(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      tokenType: 'Bearer',
      expiresIn: 900,
      sessionExpiresAt: DateTime(2026),
      user: _user,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> hasLocalSession() async => false;

  @override
  Future<String> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async => 'Cuenta creada.';

  @override
  Future<String> requestPasswordReset(String email) async => 'Correo enviado.';

  @override
  Future<String> resetPassword({
    required String token,
    required String password,
  }) async => 'Contrasena actualizada.';

  @override
  Future<AuthUser?> verifySession() async => null;
}
