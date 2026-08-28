import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/constants/app_keys.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/layout/responsive_breakpoints.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_list_filter_bar.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../reader/domain/entities/reading_progress.dart';
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
  final _searchController = TextEditingController();
  DateTime? _lastBackPressedAt;
  String _query = '';
  String? _levelCode;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          titleSpacing: 12,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Image.asset(
              AppInfo.logoAsset,
              height: 30,
              semanticLabel: '${AppInfo.displayName} logo',
              fit: BoxFit.contain,
            ),
          ),
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
                return AppEmptyState(
                  icon: Icons.library_books_outlined,
                  title: 'No hay historias disponibles',
                  message: 'Cuando haya contenido publicado aparecerá aquí.',
                  action: OutlinedButton.icon(
                    onPressed: () =>
                        context.read<StoriesBloc>().add(const StoriesLoaded()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar'),
                  ),
                );
              case StoriesStatus.error:
                return AppErrorView(
                  title: 'No se pudieron cargar las historias',
                  message:
                      state.message ?? 'No se pudieron cargar las historias.',
                  onRetry: () =>
                      context.read<StoriesBloc>().add(const StoriesLoaded()),
                );
              case StoriesStatus.success:
                final stories = _filterStories(state.stories);
                return Column(
                  children: [
                    AppListFilterBar(
                      searchFieldKey: AppKeys.storiesSearchField,
                      controller: _searchController,
                      searchLabel: 'Buscar historias',
                      onQueryChanged: (value) =>
                          setState(() => _query = value.trim()),
                      options: _levelOptions(state.stories),
                      selectedOption: _levelCode,
                      onOptionSelected: (value) =>
                          setState(() => _levelCode = value),
                      resultsLabel: _resultsLabel(
                        visible: stories.length,
                        total: state.stories.length,
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => context.read<StoriesBloc>().add(
                          const StoriesLoaded(),
                        ),
                        child: stories.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  AppEmptyState(
                                    icon: Icons.search_off_outlined,
                                    title: 'Sin coincidencias',
                                    message:
                                        'Ajusta el nivel o prueba con otro título, autor o género.',
                                    action: OutlinedButton.icon(
                                      onPressed: _clearFilters,
                                      icon: const Icon(Icons.filter_alt_off),
                                      label: const Text('Quitar filtros'),
                                    ),
                                  ),
                                ],
                              )
                            : _StoriesResponsiveList(
                                stories: stories,
                                progressByStory: state.progressByStory,
                              ),
                      ),
                    ),
                  ],
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

  /// Filtra en memoria los datos cargados para responder al usuario al instante.
  List<Story> _filterStories(List<Story> stories) {
    final query = _query.toLowerCase();
    final levelCode = _levelCode;
    if (query.isEmpty && levelCode == null) return stories;

    return stories
        .where((story) {
          if (levelCode != null && story.readingLevel.code != levelCode) {
            return false;
          }
          if (query.isEmpty) return true;

          final searchable = [
            story.title,
            story.summary,
            story.author,
            story.readingLevel.name,
            story.readingLevel.code,
            ...story.genres.map((genre) => genre.name),
          ].whereType<String>().join(' ').toLowerCase();

          return searchable.contains(query);
        })
        .toList(growable: false);
  }

  /// Deriva los niveles disponibles del lote cargado para no fijar catálogos.
  List<AppFilterOption> _levelOptions(List<Story> stories) {
    final options = <String, AppFilterOption>{};
    for (final story in stories) {
      options.putIfAbsent(
        story.readingLevel.code,
        () => AppFilterOption(
          value: story.readingLevel.code,
          label: story.readingLevel.name,
        ),
      );
    }

    final sorted = options.values.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted;
  }

  /// Describe cuántas historias quedan visibles tras aplicar filtros.
  String? _resultsLabel({required int visible, required int total}) {
    if (_query.isEmpty && _levelCode == null) return null;
    return visible == 1
        ? '1 historia de $total'
        : '$visible historias de $total';
  }

  /// Restablece búsqueda y nivel para volver al catálogo completo.
  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _levelCode = null;
    });
  }
}

/// Cambia entre lista móvil y grid amplio sin alterar la navegación.
class _StoriesResponsiveList extends StatelessWidget {
  const _StoriesResponsiveList({
    required this.stories,
    required this.progressByStory,
  });

  final List<Story> stories;
  final Map<String, ReadingProgress> progressByStory;

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
                progress: progressByStory[story.id],
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
                progress: progressByStory[story.id],
                onTap: () => context.go(AppRoutes.readerPath(story.id)),
              ),
            );
          },
        );
      },
    );
  }
}
