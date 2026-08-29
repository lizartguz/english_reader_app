import 'package:english_reader_app/core/constants/app_keys.dart';
import 'package:english_reader_app/core/constants/app_routes.dart';
import 'package:english_reader_app/features/auth/domain/entities/auth_session.dart';
import 'package:english_reader_app/features/auth/domain/entities/auth_user.dart';
import 'package:english_reader_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:english_reader_app/features/auth/presentation/cubit/account_cubit.dart';
import 'package:english_reader_app/features/auth/presentation/pages/reset_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('envia el token inicial que llega desde el enlace', (
    tester,
  ) async {
    final repository = _RecordingAuthRepository();
    await _pumpResetPassword(tester, repository, initialToken: 'token-123');

    await tester.enterText(
      find.byKey(AppKeys.resetPasswordField),
      'Cliente123',
    );
    await tester.tap(find.byKey(AppKeys.resetPasswordSubmitButton));
    await tester.pumpAndSettle();

    expect(repository.lastToken, 'token-123');
    expect(find.text('Pantalla de login'), findsOneWidget);
  });

  testWidgets('extrae el token si el usuario pega el enlace completo', (
    tester,
  ) async {
    final repository = _RecordingAuthRepository();
    await _pumpResetPassword(tester, repository);

    await tester.enterText(
      find.byKey(AppKeys.resetPasswordTokenField),
      'https://app.readeriz.com/reset-password?token=url-token&src=email',
    );
    await tester.enterText(
      find.byKey(AppKeys.resetPasswordField),
      'Cliente123',
    );
    await tester.tap(find.byKey(AppKeys.resetPasswordSubmitButton));
    await tester.pumpAndSettle();

    expect(repository.lastToken, 'url-token');
  });
}

/// Monta el reset con router real para probar navegacion y formulario juntos.
Future<void> _pumpResetPassword(
  WidgetTester tester,
  AuthRepository repository, {
  String? initialToken,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => BlocProvider(
          create: (_) => AccountCubit(repository),
          child: ResetPasswordPage(initialToken: initialToken),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) =>
            const Scaffold(body: Text('Pantalla de login')),
      ),
    ],
    initialLocation: AppRoutes.resetPassword,
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

/// Repositorio que guarda el token enviado sin llamar a la API.
class _RecordingAuthRepository implements AuthRepository {
  String? lastToken;

  @override
  Future<String> resetPassword({
    required String token,
    required String password,
  }) async {
    lastToken = token;
    return 'Contrasena actualizada.';
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<String> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<String> requestPasswordReset(String email) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser?> verifySession() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> hasLocalSession() async => false;
}
