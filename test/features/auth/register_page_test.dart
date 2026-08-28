import 'package:english_reader_app/core/constants/app_keys.dart';
import 'package:english_reader_app/features/auth/domain/entities/auth_session.dart';
import 'package:english_reader_app/features/auth/domain/entities/auth_user.dart';
import 'package:english_reader_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:english_reader_app/features/auth/presentation/cubit/account_cubit.dart';
import 'package:english_reader_app/features/auth/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'Bloquea el registro cuando la contraseña no cumple la política',
    (tester) async {
      final repository = _RecordingAuthRepository();
      await _pumpRegister(tester, repository);

      await _fillForm(tester, password: 'corta');
      await tester.tap(find.byKey(AppKeys.registerSubmitButton));
      await tester.pumpAndSettle();

      expect(find.text('Debe tener al menos 8 caracteres.'), findsOneWidget);
      expect(repository.registeredEmails, isEmpty);
    },
  );

  testWidgets('Envía el registro cuando los datos son válidos', (tester) async {
    final repository = _RecordingAuthRepository();
    await _pumpRegister(tester, repository);

    await _fillForm(tester, password: 'Cliente123');
    await tester.tap(find.byKey(AppKeys.registerSubmitButton));
    await tester.pumpAndSettle();

    expect(repository.registeredEmails, ['nuevo@correo.com']);
    expect(find.text('Pantalla de login'), findsOneWidget);
  });
}

/// Monta la pantalla con router real para poder verificar la navegacion.
Future<void> _pumpRegister(
  WidgetTester tester,
  AuthRepository repository,
) async {
  await tester.binding.setSurfaceSize(const Size(430, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/register',
        builder: (context, state) => BlocProvider(
          create: (_) => AccountCubit(repository),
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const Scaffold(body: Text('Pantalla de login')),
      ),
    ],
    initialLocation: '/register',
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

/// Rellena el formulario variando solo la contraseña bajo prueba.
Future<void> _fillForm(WidgetTester tester, {required String password}) async {
  await tester.enterText(find.byKey(AppKeys.registerFirstNameField), 'Ana');
  await tester.enterText(find.byKey(AppKeys.registerLastNameField), 'García');
  await tester.enterText(
    find.byKey(AppKeys.registerEmailField),
    'nuevo@correo.com',
  );
  await tester.enterText(find.byKey(AppKeys.registerPasswordField), password);
  await tester.pumpAndSettle();
}

/// Repositorio que registra las llamadas para verificar la validación local.
class _RecordingAuthRepository implements AuthRepository {
  final List<String> registeredEmails = [];

  @override
  Future<String> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    registeredEmails.add(email);
    return 'Cuenta creada.';
  }

  @override
  Future<String> requestPasswordReset(String email) async => 'Correo enviado.';

  @override
  Future<String> resetPassword({
    required String token,
    required String password,
  }) async => 'Contraseña actualizada.';

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
