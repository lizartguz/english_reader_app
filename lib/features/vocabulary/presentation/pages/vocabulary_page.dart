import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/layout/responsive_breakpoints.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../domain/entities/vocabulary_entry.dart';
import '../bloc/vocabulary_bloc.dart';

/// Pantalla del vocabulario personal sincronizado con la API.
class VocabularyPage extends StatelessWidget {
  const VocabularyPage({super.key});

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
              VocabularyStatus.empty => const AppEmptyState(
                title: 'Sin palabras guardadas',
                message:
                    'Toca palabras dentro del lector para guardarlas aquí.',
              ),
              VocabularyStatus.error => AppErrorView(
                message: state.message ?? 'No se pudo cargar el vocabulario.',
                onRetry: () => context.read<VocabularyBloc>().add(
                  const VocabularyLoaded(),
                ),
              ),
              VocabularyStatus.success => RefreshIndicator(
                onRefresh: () async => context.read<VocabularyBloc>().add(
                  const VocabularyLoaded(),
                ),
                child: _VocabularyResponsiveList(state: state),
              ),
            };
          },
        ),
      ),
    );
  }
}

/// Lista de vocabulario con ancho estable para móvil y Web.
class _VocabularyResponsiveList extends StatelessWidget {
  const _VocabularyResponsiveList({required this.state});

  final VocabularyState state;

  /// Construye filas centradas para conservar lectura rápida en pantallas grandes.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.separated(
          key: AppKeys.vocabularyList,
          padding: ResponsiveBreakpoints.pagePadding(constraints.maxWidth),
          itemCount: state.entries.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entry = state.entries[index];
            return ResponsiveContentWidth(
              child: _VocabularyTile(
                entry: entry,
                busy: state.busyEntryId == entry.id,
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

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Vocabulario'));
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
    return ListTile(
      key: AppKeys.vocabularyTile(entry.id),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      title: Text(entry.word.word),
      subtitle: Text(_subtitle),
      trailing: busy
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : PopupMenuButton<String>(
              key: AppKeys.vocabularyActions(entry.id),
              tooltip: 'Acciones',
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
    );
  }

  String get _subtitle {
    return [
      if (entry.word.primaryTranslation != null) entry.word.primaryTranslation,
      if (entry.storyTitle != null) entry.storyTitle,
      _statusLabel(entry.status),
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

  /// Traduce estados internos a etiquetas visibles para el usuario.
  String _statusLabel(String status) {
    return switch (status) {
      'learning' => 'En aprendizaje',
      'learned' => 'Aprendida',
      'archived' => 'Archivada',
      _ => 'Guardada',
    };
  }
}
