import 'package:english_reader_app/features/reader/domain/entities/word_detail.dart';
import 'package:english_reader_app/features/vocabulary/domain/entities/vocabulary_entry.dart';
import 'package:english_reader_app/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:english_reader_app/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VocabularyBloc', () {
    test('carga vocabulario y emite estado exitoso', () async {
      final repository = _FakeVocabularyRepository(entries: [_entry]);
      final bloc = VocabularyBloc(repository);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<VocabularyState>().having(
            (state) => state.status,
            'status',
            VocabularyStatus.loading,
          ),
          isA<VocabularyState>()
              .having(
                (state) => state.status,
                'status',
                VocabularyStatus.success,
              )
              .having((state) => state.entries.length, 'entries', 1),
        ]),
      );

      bloc.add(const VocabularyLoaded());

      await expectation;
      await bloc.close();
    });

    test('actualiza estado de aprendizaje en la lista cargada', () async {
      final repository = _FakeVocabularyRepository(entries: [_entry]);
      final bloc = VocabularyBloc(repository);

      bloc
        ..add(const VocabularyLoaded())
        ..add(const VocabularyStatusChanged(id: 'saved-1', status: 'learned'));

      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<VocabularyState>().having(
            (state) => state.entries.first.status,
            'status',
            'learned',
          ),
        ),
      );
      await bloc.close();
    });
  });
}

final _entry = VocabularyEntry(
  id: 'saved-1',
  status: 'saved',
  savedAt: DateTime(2026),
  word: const WordDetail(
    id: 'word-1',
    word: 'beautiful',
    normalizedWord: 'beautiful',
    language: 'en',
    translations: [
      WordTranslation(
        id: 'translation-1',
        targetLanguage: 'es',
        translation: 'hermoso',
      ),
    ],
    examples: [],
    pronunciations: [],
    isSaved: true,
    savedWordId: 'saved-1',
  ),
);

/// Repositorio de prueba que simula las respuestas vigentes de la API.
class _FakeVocabularyRepository implements VocabularyRepository {
  _FakeVocabularyRepository({required List<VocabularyEntry> entries})
    : _entries = entries;

  List<VocabularyEntry> _entries;

  /// Devuelve una copia para evitar que el BLoC modifique el origen fake.
  @override
  Future<List<VocabularyEntry>> listVocabulary() async {
    return List<VocabularyEntry>.from(_entries);
  }

  /// Simula la edición que realiza `PATCH /app/vocabulary/:id`.
  @override
  Future<VocabularyEntry> updateVocabulary({
    required String id,
    String? status,
    String? notes,
  }) async {
    final index = _entries.indexWhere((entry) => entry.id == id);
    final current = _entries[index];
    final updated = VocabularyEntry(
      id: current.id,
      status: status ?? current.status,
      notes: notes ?? current.notes,
      savedAt: current.savedAt,
      word: current.word,
      storyTitle: current.storyTitle,
    );
    _entries = [..._entries.take(index), updated, ..._entries.skip(index + 1)];
    return updated;
  }

  /// Simula la eliminación personal sin tocar la palabra global.
  @override
  Future<void> deleteVocabulary(String id) async {
    _entries = _entries.where((entry) => entry.id != id).toList();
  }
}
