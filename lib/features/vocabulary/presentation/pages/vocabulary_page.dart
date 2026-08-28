import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accessibility/app_semantics.dart';
import '../../../../core/constants/app_keys.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/layout/responsive_breakpoints.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_list_filter_bar.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../domain/entities/vocabulary_entry.dart';
import '../bloc/vocabulary_bloc.dart';

/// Traduce estados internos a etiquetas visibles para el usuario.
String _statusLabel(String status) {
  return switch (status) {
    'learning' => 'En aprendizaje',
    'learned' => 'Aprendida',
    'archived' => 'Archivada',
    _ => 'Guardada',
  };
}

/// Pantalla del vocabulario personal sincronizado con la API.
class VocabularyPage extends StatefulWidget {
  const VocabularyPage({super.key});

  @override
  State<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _status;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Construye vocabulario con filtro local y mensajes recuperables.
  @override
  Widget build(BuildContext context) {
    return BlocListener<VocabularyBloc, VocabularyState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        final message = state.message;
        if (message == null || message.isEmpty) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
      child: Scaffold(
        appBar: const _VocabularyAppBar(),
        body: BlocBuilder<VocabularyBloc, VocabularyState>(
          builder: (context, state) {
            return switch (state.status) {
              VocabularyStatus.initial || VocabularyStatus.loading =>
                const AppLoadingView(message: 'Cargando vocabulario...'),
              VocabularyStatus.empty => AppEmptyState(
                icon: Icons.bookmark_border,
                title: 'Sin palabras guardadas',
                message:
                    'Toca palabras dentro del lector para guardarlas aquí.',
                action: OutlinedButton.icon(
                  onPressed: () => context.read<VocabularyBloc>().add(
                    const VocabularyLoaded(),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
              ),
              VocabularyStatus.error => AppErrorView(
                title: 'No se pudo cargar el vocabulario',
                message: state.message ?? 'No se pudo cargar el vocabulario.',
                onRetry: () => context.read<VocabularyBloc>().add(
                  const VocabularyLoaded(),
                ),
              ),
              VocabularyStatus.success => _VocabularyBody(
                entries: _filteredEntries(state.entries),
                busyEntryId: state.busyEntryId,
                searchController: _searchController,
                selectedStatus: _status,
                resultsLabel: _resultsLabel(
                  visible: _filteredEntries(state.entries).length,
                  total: state.entries.length,
                ),
                onQueryChanged: (value) =>
                    setState(() => _query = value.trim()),
                onStatusSelected: (value) => setState(() => _status = value),
                onClearFilters: _clearFilters,
              ),
            };
          },
        ),
      ),
    );
  }

  /// Filtra el vocabulario cargado sin consultar de nuevo al backend.
  List<VocabularyEntry> _filteredEntries(List<VocabularyEntry> entries) {
    final query = _query.toLowerCase();
    final status = _status;
    if (query.isEmpty && status == null) return entries;

    return entries
        .where((entry) {
          if (status != null && entry.status != status) return false;
          if (query.isEmpty) return true;

          final searchable = [
            entry.word.word,
            entry.word.primaryTranslation,
            entry.storyTitle,
            entry.notes,
            _statusLabel(entry.status),
          ].whereType<String>().join(' ').toLowerCase();

          return searchable.contains(query);
        })
        .toList(growable: false);
  }

  /// Describe cuántas palabras quedan visibles tras aplicar filtros.
  String? _resultsLabel({required int visible, required int total}) {
    if (_query.isEmpty && _status == null) return null;
    return visible == 1 ? '1 palabra de $total' : '$visible palabras de $total';
  }

  /// Restablece búsqueda y estado para volver al vocabulario completo.
  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _status = null;
    });
  }
}

/// Cuerpo del vocabulario con filtros, recarga y estados sin resultados.
class _VocabularyBody extends StatelessWidget {
  const _VocabularyBody({
    required this.entries,
    required this.busyEntryId,
    required this.searchController,
    required this.selectedStatus,
    required this.resultsLabel,
    required this.onQueryChanged,
    required this.onStatusSelected,
    required this.onClearFilters,
  });

  final List<VocabularyEntry> entries;
  final String? busyEntryId;
  final TextEditingController searchController;
  final String? selectedStatus;
  final String? resultsLabel;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onStatusSelected;
  final VoidCallback onClearFilters;

  /// Combina la barra de filtros con la lista filtrada de palabras guardadas.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppListFilterBar(
          searchFieldKey: AppKeys.vocabularySearchField,
          controller: searchController,
          searchLabel: 'Buscar vocabulario',
          onQueryChanged: onQueryChanged,
          options: _statusOptions,
          selectedOption: selectedStatus,
          onOptionSelected: onStatusSelected,
          resultsLabel: resultsLabel,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async =>
                context.read<VocabularyBloc>().add(const VocabularyLoaded()),
            child: entries.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      AppEmptyState(
                        icon: Icons.search_off_outlined,
                        title: 'Sin coincidencias',
                        message:
                            'Ajusta el estado o prueba con otra palabra, traducción o nota.',
                        action: OutlinedButton.icon(
                          onPressed: onClearFilters,
                          icon: const Icon(Icons.filter_alt_off),
                          label: const Text('Quitar filtros'),
                        ),
                      ),
                    ],
                  )
                : _VocabularyResponsiveList(
                    entries: entries,
                    busyEntryId: busyEntryId,
                  ),
          ),
        ),
      ],
    );
  }
}

/// Estados soportados por la API para clasificar el vocabulario personal.
const _statusOptions = <AppFilterOption>[
  AppFilterOption(value: 'saved', label: 'Guardada'),
  AppFilterOption(value: 'learning', label: 'En aprendizaje'),
  AppFilterOption(value: 'learned', label: 'Aprendida'),
  AppFilterOption(value: 'archived', label: 'Archivada'),
];

/// Lista de vocabulario con ancho estable para móvil y Web.
class _VocabularyResponsiveList extends StatelessWidget {
  const _VocabularyResponsiveList({
    required this.entries,
    required this.busyEntryId,
  });

  final List<VocabularyEntry> entries;
  final String? busyEntryId;

  /// Construye filas centradas para conservar lectura rápida en pantallas grandes.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.separated(
          key: AppKeys.vocabularyList,
          padding: ResponsiveBreakpoints.pagePadding(constraints.maxWidth),
          itemCount: entries.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ResponsiveContentWidth(
              child: _VocabularyTile(
                entry: entry,
                busy: busyEntryId == entry.id,
              ),
            );
          },
        );
      },
    );
  }
}

/// AppBar separado para mantener estable la pantalla principal.
class _VocabularyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _VocabularyAppBar();

  /// Conserva una salida visible hacia historias en móvil y Web.
  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        tooltip: 'Volver a historias',
        onPressed: () => context.go(AppRoutes.home),
        icon: const Icon(Icons.arrow_back),
      ),
      title: const Text('Vocabulario'),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Fila editable de una palabra guardada por el usuario.
class _VocabularyTile extends StatelessWidget {
  const _VocabularyTile({required this.entry, required this.busy});

  final VocabularyEntry entry;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusLabel(entry.status);

    return Padding(
      key: AppKeys.vocabularyTile(entry.id),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: AppSemantics.vocabularyEntry(
                word: entry.word.word,
                translation: entry.word.primaryTranslation,
                status: statusLabel,
              ),
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.word.word,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(statusLabel),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          busy
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : PopupMenuButton<String>(
                  key: AppKeys.vocabularyActions(entry.id),
                  tooltip: AppSemantics.vocabularyActions(entry.word.word),
                  onSelected: (value) => _handleAction(context, value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'status:saved',
                      child: Text('Marcar como guardada'),
                    ),
                    PopupMenuItem(
                      value: 'status:learning',
                      child: Text('Marcar en aprendizaje'),
                    ),
                    PopupMenuItem(
                      value: 'status:learned',
                      child: Text('Marcar aprendida'),
                    ),
                    PopupMenuItem(
                      value: 'status:archived',
                      child: Text('Archivar'),
                    ),
                    PopupMenuItem(value: 'notes', child: Text('Editar nota')),
                    PopupMenuDivider(),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
        ],
      ),
    );
  }

  /// Une datos de estudio en una sola línea para lectura rápida.
  String _subtitle(String statusLabel) {
    return [
      if (entry.word.primaryTranslation != null) entry.word.primaryTranslation,
      if (entry.storyTitle != null) entry.storyTitle,
      statusLabel,
      if (entry.notes != null && entry.notes!.isNotEmpty) entry.notes,
    ].join(' · ');
  }

  /// Ejecuta acciones soportadas por los endpoints vigentes de vocabulario.
  void _handleAction(BuildContext context, String action) {
    if (action.startsWith('status:')) {
      context.read<VocabularyBloc>().add(
        VocabularyStatusChanged(id: entry.id, status: action.split(':').last),
      );
      return;
    }

    if (action == 'notes') {
      _showNotesDialog(context);
      return;
    }

    if (action == 'delete') {
      _confirmDelete(context);
    }
  }

  /// Solicita una nota corta y la delega al BLoC para persistirla.
  Future<void> _showNotesDialog(BuildContext context) async {
    final controller = TextEditingController(text: entry.notes ?? '');
    final notes = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nota de estudio'),
        content: TextField(
          key: AppKeys.vocabularyNotesField,
          controller: controller,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(hintText: 'Escribe una nota breve'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: AppKeys.vocabularyNotesSave,
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (notes == null || !context.mounted) return;

    context.read<VocabularyBloc>().add(
      VocabularyNotesChanged(id: entry.id, notes: notes.trim()),
    );
  }

  /// Pide confirmación antes de eliminar un registro personal.
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar palabra'),
        content: Text('¿Eliminar "${entry.word.word}" de tu vocabulario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    context.read<VocabularyBloc>().add(VocabularyDeleted(entry.id));
  }
}
