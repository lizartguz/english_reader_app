import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
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
    final isLogin = location == AppRoutes.login;

    if (status == AuthStatus.initial || status == AuthStatus.checking) {
      return isSplash ? null : AppRoutes.splash;
    }

    if (status == AuthStatus.authenticated) {
      return isSplash || isLogin ? AppRoutes.stories : null;
    }

    return isLogin ? null : AppRoutes.login;
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
