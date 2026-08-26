import 'package:english_reader_app/features/reader/domain/entities/reading_progress.dart';
import 'package:english_reader_app/features/reader/domain/entities/word_detail.dart';
import 'package:english_reader_app/features/reader/domain/repositories/reader_repository.dart';
import 'package:english_reader_app/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:english_reader_app/features/stories/domain/entities/story.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderBloc', () {
    test('carga historia y restaura progreso existente', () async {
      final repository = _FakeReaderRepository();
      final bloc = ReaderBloc(repository);

      final expectation = expectLater(
        bloc.stream,
        emitsThrough(
          isA<ReaderState>()
              .having((state) => state.status, 'status', ReaderStatus.success)
              .having(
                (state) => state.visibleProgressPercent,
                'visibleProgressPercent',
                25,
              )
              .having(
                (state) => state.effectiveLastPosition,
                'lastPosition',
                'scroll:120',
              ),
        ),
      );

      bloc.add(const ReaderStarted('story-1'));

      await expectation;
      await bloc.close();
    });

    test('actualiza progreso visual antes de persistirlo', () async {
      final repository = _FakeReaderRepository();
      final bloc = ReaderBloc(repository);

      bloc.add(const ReaderStarted('story-1'));
      await bloc.stream.firstWhere(
        (state) => state.status == ReaderStatus.success,
      );

      final expectation = expectLater(
        bloc.stream,
        emits(
          isA<ReaderState>()
              .having(
                (state) => state.visibleProgressPercent,
                'visibleProgressPercent',
                64.5,
              )
              .having(
                (state) => state.effectiveLastPosition,
                'lastPosition',
                'scroll:310',
              ),
        ),
      );

      bloc.add(
        const ReaderProgressPreviewChanged(
          progressPercent: 64.5,
          lastPosition: 'scroll:310',
        ),
      );

      await expectation;
      await bloc.close();
    });

    test('sincroniza progreso sin mensaje cuando notify es falso', () async {
      final repository = _FakeReaderRepository();
      final bloc = ReaderBloc(repository);

      bloc.add(const ReaderStarted('story-1'));
      await bloc.stream.firstWhere(
        (state) => state.status == ReaderStatus.success,
      );

      final expectation = expectLater(
        bloc.stream,
        emitsThrough(
          isA<ReaderState>()
              .having(
                (state) => state.progress?.progressPercent,
                'progress',
                80,
              )
              .having((state) => state.message, 'message', null),
        ),
      );

      bloc.add(
        const ReaderProgressSaved(
          progressPercent: 80,
          lastPosition: 'scroll:500',
          notify: false,
        ),
      );

      await expectation;
      await bloc.close();
    });
  });
}

/// Repositorio fake para probar el BLoC sin depender de red.
class _FakeReaderRepository implements ReaderRepository {
  ReadingProgress _progress = ReadingProgress(
    id: 'progress-1',
    userId: 'user-1',
    storyId: 'story-1',
    progressPercent: 25,
    lastPosition: 'scroll:120',
    lastReadAt: DateTime(2026),
  );

  /// Devuelve una historia mínima suficiente para activar el lector.
  @override
  Future<Story> getStory(String storyId) async {
    return const Story(
      id: 'story-1',
      title: 'A Test Story',
      slug: 'a-test-story',
      status: 'published',
      sortOrder: 1,
      readingLevel: StoryReadingLevel(
        id: 'level-1',
        code: 'A1',
        name: 'Principiante',
      ),
      genres: [],
      assets: [],
      content: 'Once upon a time.',
    );
  }

  /// Devuelve el progreso inicial como lo entregaría la API.
  @override
  Future<ReadingProgress?> getProgress(String storyId) async => _progress;

  /// Persiste el avance calculado por la UI.
  @override
  Future<ReadingProgress> saveProgress({
    required String storyId,
    required double progressPercent,
    String? lastPosition,
    bool? completed,
  }) async {
    _progress = ReadingProgress(
      id: 'progress-1',
      userId: 'user-1',
      storyId: storyId,
      progressPercent: progressPercent,
      lastPosition: lastPosition,
      completedAt: completed == true ? DateTime(2026) : null,
      lastReadAt: DateTime(2026),
    );
    return _progress;
  }

  /// No se usa en estos casos; se mantiene por contrato.
  @override
  Future<WordDetail> lookupWord(String word) {
    throw UnimplementedError();
  }

  /// No se usa en estos casos; se mantiene por contrato.
  @override
  Future<WordDetail> saveVocabulary({
    required String wordEntryId,
    required String storyId,
  }) {
    throw UnimplementedError();
  }
}
