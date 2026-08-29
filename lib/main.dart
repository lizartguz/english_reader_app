import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'app/di/app_dependencies.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/constants/app_info.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/reader/presentation/cubit/reader_settings_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = await AppDependencies.create();
  final authBloc = AuthBloc(dependencies.authRepository)
    ..add(const AuthStarted());
  dependencies.apiClient.sessionIssues.listen(
    (issue) => authBloc.add(AuthSessionExpired(issue.message)),
  );
  final router = AppRouter(authBloc: authBloc).router;

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDependencies>.value(value: dependencies),
        Provider.value(value: dependencies.apiClient),
        Provider.value(value: dependencies.storyAssetLoader),
        Provider.value(value: dependencies.authRepository),
        Provider.value(value: dependencies.storiesRepository),
        Provider.value(value: dependencies.readerRepository),
        Provider.value(value: dependencies.vocabularyRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider(
            create: (_) =>
                ReaderSettingsCubit(dependencies.preferences)..load(),
          ),
        ],
        child: EnglishReaderApp(router: router),
      ),
    ),
  );
}

class EnglishReaderApp extends StatelessWidget {
  const EnglishReaderApp({required this.router, super.key});

  final AppRouterConfig router;

  /// Construye la aplicación raíz con navegación protegida por sesión.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppInfo.displayName,
      theme: AppTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
