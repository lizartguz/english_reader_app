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

void main() {
  testWidgets('LoginPage envía credenciales al AuthBloc', (tester) async {
    final repository = _FakeAuthRepository();
    final bloc = AuthBloc(repository);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: bloc, child: const LoginPage()),
      ),
    );

    await tester.enterText(
      find.byKey(AppKeys.loginEmailField),
      'cliente.flutter.test@englishreader.local',
    );
    await tester.enterText(
      find.byKey(AppKeys.loginPasswordField),
      'Cliente123*',
    );
    await tester.tap(find.byKey(AppKeys.loginSubmitButton));
    await tester.pump(const Duration(milliseconds: 50));

    expect(repository.lastEmail, 'cliente.flutter.test@englishreader.local');
    expect(repository.lastPassword, 'Cliente123*');

    unawaited(bloc.close());
  });
}

/// Repositorio fake para probar el formulario sin llamar a la API real.
class _FakeAuthRepository implements AuthRepository {
  String? lastEmail;
  String? lastPassword;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;

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
  Future<AuthUser?> verifySession() async => null;
}

const _user = AuthUser(
  id: 'user-1',
  email: 'cliente.flutter.test@englishreader.local',
  firstName: 'Cliente',
  lastName: 'Flutter',
  fullName: 'Cliente Flutter',
  status: 'active',
  roles: ['CLIENT'],
  permissions: [],
);
