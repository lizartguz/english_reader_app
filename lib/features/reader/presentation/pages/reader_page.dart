import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/accessibility/app_semantics.dart';
import '../../../../core/constants/app_keys.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../bloc/reader_bloc.dart';
import '../cubit/reader_settings_cubit.dart';
import '../widgets/reader_content.dart';
import '../widgets/reader_settings_sheet.dart';
import '../widgets/word_detail_sheet.dart';

/// Pantalla de lectura que coordina historia, palabras y progreso.
class ReaderPage extends StatelessWidget {
  const ReaderPage({required this.storyId, super.key});

  final String storyId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReaderBloc, ReaderState>(
      listenWhen: (previous, current) =>
          previous.wordStatus != current.wordStatus ||
          previous.message != current.message,
      listener: (context, state) {
        final message = state.message;
        if (message != null && message.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }

        if (state.wordStatus == WordLookupStatus.success &&
            state.selectedWord != null) {
          final bloc = context.read<ReaderBloc>();
          showModalBottomSheet<void>(
            context: context,
            showDragHandle: false,
            isScrollControlled: true,
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: BlocBuilder<ReaderBloc, ReaderState>(
                builder: (context, sheetState) {
                  return WordDetailSheet(
                    word: sheetState.selectedWord ?? state.selectedWord!,
                    isSaving: sheetState.isSavingVocabulary,
                    onSave: () => context.read<ReaderBloc>().add(
                      const ReaderVocabularySaved(),
                    ),
                  );
                },
              ),
            ),
          ).whenComplete(() => bloc.add(const ReaderWordDismissed()));
        }
      },
      builder: (context, state) {
        final story = state.story;
        return Scaffold(
          appBar: AppBar(
            title: Text(story?.title ?? 'Lector'),
            actions: [
              IconButton(
                key: AppKeys.readerSettingsButton,
                tooltip: 'Ajustes de lectura',
                onPressed: () => _showReaderSettings(context),
                icon: const Icon(Icons.tune),
              ),
              if (story != null)
                IconButton(
                  tooltip: 'Marcar como completada',
                  onPressed: () => context.read<ReaderBloc>().add(
                    const ReaderProgressSaved(
                      progressPercent: 100,
                      completed: true,
                    ),
                  ),
                  icon: const Icon(Icons.done_all),
                ),
            ],
          ),
          body: switch (state.status) {
            ReaderStatus.initial || ReaderStatus.loading =>
              const AppLoadingView(message: 'Abriendo lectura...'),
            ReaderStatus.error => AppErrorView(
              message: state.message ?? 'No se pudo cargar la historia.',
              onRetry: () =>
                  context.read<ReaderBloc>().add(ReaderStarted(storyId)),
            ),
            ReaderStatus.success => _ReaderBody(state: state),
          },
        );
      },
    );
  }

  /// Abre los controles locales de comodidad visual del lector.
  void _showReaderSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ReaderSettingsCubit>(),
        child: const ReaderSettingsSheet(),
      ),
    );
  }
}

/// Cuerpo scrollable que calcula el avance real de lectura.
class _ReaderBody extends StatefulWidget {
  const _ReaderBody({required this.state});

  final ReaderState state;

  @override
  State<_ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends State<_ReaderBody> {
  final ScrollController _scrollController = ScrollController();
  Timer? _saveDebounce;
  bool _restoredPosition = false;
  double _lastSavedPercent = -1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restorePositionOnce();
  }

  @override
  void didUpdateWidget(covariant _ReaderBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.story?.id != widget.state.story?.id) {
      _restoredPosition = false;
      _lastSavedPercent = -1;
      _restorePositionOnce();
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.state.story!;
    final progress = widget.state.visibleProgressPercent;
    final settings = context.watch<ReaderSettingsCubit>().state;

    return Column(
      children: [
        Semantics(
          label: AppSemantics.readingProgress(progress),
          value: '${progress.round()}%',
          liveRegion: true,
          child: LinearProgressIndicator(value: progress.clamp(0, 100) / 100),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: AppKeys.readerScroll,
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.readingLevel.name,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      story.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (story.summary != null && story.summary!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        story.summary!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    const SizedBox(height: 28),
                    FocusTraversalGroup(
                      policy: ReadingOrderTraversalPolicy(),
                      child: ReaderContent(
                        content: story.content ?? '',
                        fontScale: settings.fontScale,
                        lineHeight: settings.lineHeight,
                        onWordTap: (word) => context.read<ReaderBloc>().add(
                          ReaderWordSelected(word),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Restaura la última posición guardada por la API cuando está disponible.
  void _restorePositionOnce() {
    if (_restoredPosition) return;
    _restoredPosition = true;

    final position = widget.state.effectiveLastPosition;
    if (position == null || !position.startsWith('scroll:')) return;

    final offset = double.tryParse(position.replaceFirst('scroll:', ''));
    if (offset == null || offset <= 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxOffset = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(offset.clamp(0, maxOffset));
    });
  }

  /// Calcula progreso por scroll y programa una sincronización moderada.
  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final offset = position.pixels.clamp(0, maxScroll);
    final progress = maxScroll <= 0 ? 100.0 : (offset / maxScroll) * 100;
    final roundedProgress = double.parse(
      progress.clamp(0, 100).toStringAsFixed(1),
    );
    final lastPosition = 'scroll:${offset.round()}';

    context.read<ReaderBloc>().add(
      ReaderProgressPreviewChanged(
        progressPercent: roundedProgress,
        lastPosition: lastPosition,
      ),
    );

    if ((roundedProgress - _lastSavedPercent).abs() < 3 &&
        roundedProgress < 99.5) {
      return;
    }

    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _lastSavedPercent = roundedProgress;
      context.read<ReaderBloc>().add(
        ReaderProgressSaved(
          progressPercent: roundedProgress,
          lastPosition: lastPosition,
          completed: roundedProgress >= 99.5,
          notify: false,
        ),
      );
    });
  }
}
