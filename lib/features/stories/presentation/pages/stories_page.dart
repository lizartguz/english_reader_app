import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/layout/responsive_breakpoints.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/story.dart';
import '../bloc/stories_bloc.dart';
import '../widgets/story_card.dart';

/// Pantalla principal de historias publicada para móvil, tablet y Web.
class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  DateTime? _lastBackPressedAt;

  /// Construye el listado responsive de historias disponibles.
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_usesAndroidDoubleBack,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !_usesAndroidDoubleBack) return;
        _handleAndroidBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historias'),
          actions: [
            IconButton(
              tooltip: 'Vocabulario',
              onPressed: () => context.go(AppRoutes.vocabulary),
              icon: const Icon(Icons.bookmark_outline),
            ),
            IconButton(
              tooltip: 'Perfil',
              onPressed: () => context.go(AppRoutes.profile),
              icon: const Icon(Icons.person_outline),
            ),
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: BlocBuilder<StoriesBloc, StoriesState>(
          builder: (context, state) {
            switch (state.status) {
              case StoriesStatus.initial:
              case StoriesStatus.loading:
                return const AppLoadingView(message: 'Cargando historias...');
              case StoriesStatus.empty:
                return const AppEmptyState(
                  title: 'No hay historias disponibles',
                  message: 'Cuando haya contenido publicado aparecerá aquí.',
                );
              case StoriesStatus.error:
                return AppErrorView(
                  message:
                      state.message ?? 'No se pudieron cargar las historias.',
                  onRetry: () =>
                      context.read<StoriesBloc>().add(const StoriesLoaded()),
                );
              case StoriesStatus.success:
                return RefreshIndicator(
                  onRefresh: () async =>
                      context.read<StoriesBloc>().add(const StoriesLoaded()),
                  child: _StoriesResponsiveList(stories: state.stories),
                );
            }
          },
        ),
      ),
    );
  }

  /// Limita el doble back a Android nativo para respetar Web e iOS.
  bool get _usesAndroidDoubleBack {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  /// Pide confirmación temporal antes de salir de la pantalla principal.
  void _handleAndroidBack() {
    final now = DateTime.now();
    final lastBackPressedAt = _lastBackPressedAt;
    final canExit =
        lastBackPressedAt != null &&
        now.difference(lastBackPressedAt) <= const Duration(seconds: 2);

    if (canExit) {
      SystemNavigator.pop();
      return;
    }

    _lastBackPressedAt = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Presiona nuevamente para salir.')),
      );
  }
}

/// Cambia entre lista móvil y grid amplio sin alterar la navegación.
class _StoriesResponsiveList extends StatelessWidget {
  const _StoriesResponsiveList({required this.stories});

  final List<Story> stories;

  /// Selecciona la composición según el ancho disponible.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = ResponsiveBreakpoints.pagePadding(width);

        if (ResponsiveBreakpoints.isWide(width)) {
          return GridView.builder(
            key: AppKeys.storiesList,
            padding: padding,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 420,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.82,
            ),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return StoryCard(
                key: AppKeys.storyCard(story.id),
                story: story,
                onTap: () => context.go(AppRoutes.readerPath(story.id)),
              );
            },
          );
        }

        return ListView.separated(
          key: AppKeys.storiesList,
          padding: padding,
          itemCount: stories.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final story = stories[index];
            return ResponsiveContentWidth(
              child: StoryCard(
                key: AppKeys.storyCard(story.id),
                story: story,
                onTap: () => context.go(AppRoutes.readerPath(story.id)),
              ),
            );
          },
        );
      },
    );
  }
}
