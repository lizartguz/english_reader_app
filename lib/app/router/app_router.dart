import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/cubit/account_cubit.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reader/domain/repositories/reader_repository.dart';
import '../../features/reader/presentation/bloc/reader_bloc.dart';
import '../../features/reader/presentation/pages/reader_page.dart';
import '../../features/stories/domain/repositories/stories_repository.dart';
import '../../features/stories/presentation/bloc/stories_bloc.dart';
import '../../features/stories/presentation/pages/stories_page.dart';
import '../../features/vocabulary/domain/repositories/vocabulary_repository.dart';
import '../../features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import '../../features/vocabulary/presentation/pages/vocabulary_page.dart';

typedef AppRouterConfig = GoRouter;

class AppRouter {
  AppRouter({required this.authBloc});

  final AuthBloc authBloc;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: _redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) =>
            _accountFlow(context, const RegisterPage()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) =>
            _accountFlow(context, const ForgotPasswordPage()),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final routeData = _resetPasswordRouteData(state);
          return _accountFlow(
            context,
            ResetPasswordPage(
              initialToken: routeData.initialToken,
              cleanLocation: routeData.cleanLocation,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.stories,
        builder: (context, state) => BlocProvider(
          create: (_) =>
              StoriesBloc(context.read<StoriesRepository>())
                ..add(const StoriesLoaded()),
          child: const StoriesPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.reader,
        builder: (context, state) {
          final storyId = state.pathParameters['storyId']!;
          return BlocProvider(
            create: (_) =>
                ReaderBloc(context.read<ReaderRepository>())
                  ..add(ReaderStarted(storyId)),
            child: ReaderPage(storyId: storyId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.vocabulary,
        builder: (context, state) => BlocProvider(
          create: (_) =>
              VocabularyBloc(context.read<VocabularyRepository>())
                ..add(const VocabularyLoaded()),
          child: const VocabularyPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final status = authBloc.state.status;
    final location = state.matchedLocation;
    final isSplash = location == AppRoutes.splash;
    final isPublic = AppRoutes.publicRoutes.contains(location);

    if (status == AuthStatus.initial || status == AuthStatus.checking) {
      return isSplash ? null : AppRoutes.splash;
    }

    if (status == AuthStatus.authenticated) {
      return isSplash || isPublic ? AppRoutes.stories : null;
    }

    return isPublic ? null : AppRoutes.login;
  }

  /// Provee el cubit de cuenta a los formularios que no abren sesión.
  static Widget _accountFlow(BuildContext context, Widget child) {
    return BlocProvider(
      create: (_) => AccountCubit(context.read<AuthRepository>()),
      child: child,
    );
  }

  /// Extrae el token de reset y prepara la ruta sin datos sensibles.
  static _ResetPasswordRouteData _resetPasswordRouteData(GoRouterState state) {
    final queryParameters = _resetQueryParameters(state.uri);
    final tokenFromRoute = _firstQueryValue(queryParameters, 'token');
    final tokenFromExtra = state.extra is String ? state.extra as String : null;
    final initialToken = _firstNonEmpty(tokenFromRoute, tokenFromExtra);
    final cleanLocation = tokenFromRoute == null
        ? null
        : _cleanResetPasswordLocation(queryParameters);

    return _ResetPasswordRouteData(
      initialToken: initialToken,
      cleanLocation: cleanLocation,
    );
  }

  /// Soporta query normal y hash route, ambos usados por Flutter Web.
  static Map<String, List<String>> _resetQueryParameters(Uri uri) {
    if (uri.queryParametersAll.isNotEmpty) return uri.queryParametersAll;
    if (uri.fragment.isEmpty) return const {};

    return Uri.tryParse(uri.fragment)?.queryParametersAll ?? const {};
  }

  /// Devuelve el primer valor útil sin exponer listas al widget.
  static String? _firstQueryValue(
    Map<String, List<String>> queryParameters,
    String key,
  ) {
    final values = queryParameters[key];
    if (values == null || values.isEmpty) return null;

    return _firstNonEmpty(values.first);
  }

  /// Conserva parámetros no sensibles al reemplazar la URL del navegador.
  static String _cleanResetPasswordLocation(
    Map<String, List<String>> queryParameters,
  ) {
    final cleanParameters = <String, String>{};
    for (final entry in queryParameters.entries) {
      if (entry.key == 'token' || entry.value.isEmpty) continue;
      cleanParameters[entry.key] = entry.value.first;
    }

    if (cleanParameters.isEmpty) return AppRoutes.resetPassword;

    return Uri(
      path: AppRoutes.resetPassword,
      queryParameters: cleanParameters,
    ).toString();
  }

  /// Normaliza valores vacíos para no disparar limpiezas innecesarias.
  static String? _firstNonEmpty(String? primary, [String? fallback]) {
    final normalizedPrimary = primary?.trim();
    if (normalizedPrimary != null && normalizedPrimary.isNotEmpty) {
      return normalizedPrimary;
    }

    final normalizedFallback = fallback?.trim();
    if (normalizedFallback != null && normalizedFallback.isNotEmpty) {
      return normalizedFallback;
    }

    return null;
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Datos seguros que la ruta de reset entrega al formulario.
class _ResetPasswordRouteData {
  const _ResetPasswordRouteData({this.initialToken, this.cleanLocation});

  final String? initialToken;
  final String? cleanLocation;
}
