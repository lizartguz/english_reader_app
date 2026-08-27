import 'package:english_reader_app/core/accessibility/app_semantics.dart';
import 'package:english_reader_app/features/reader/domain/entities/word_detail.dart';
import 'package:english_reader_app/features/vocabulary/domain/entities/vocabulary_entry.dart';
import 'package:english_reader_app/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:english_reader_app/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:english_reader_app/features/vocabulary/presentation/pages/vocabulary_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VocabularyPage expone cada palabra con etiqueta semantica', (
    tester,
  ) async {
    final bloc = _SeededVocabularyBloc([_entry]);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<VocabularyBloc>.value(
          value: bloc,
          child: const VocabularyPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('beautiful'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        AppSemantics.vocabularyEntry(
          word: 'beautiful',
          translation: 'hermoso',
          status: 'Guardada',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byTooltip(AppSemantics.vocabularyActions('beautiful')),
      findsOneWidget,
    );
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

/// Repositorio fake mínimo para renderizar el vocabulario cargado.
class _FakeVocabularyRepository implements VocabularyRepository {
  const _FakeVocabularyRepository();

  /// Devuelve datos controlados sin depender de la API real.
  @override
  Future<List<VocabularyEntry>> listVocabulary() async => const [];

  @override
  Future<VocabularyEntry> updateVocabulary({
    required String id,
    String? status,
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteVocabulary(String id) async {
    throw UnimplementedError();
  }
}

/// BLoC con estado inicial cargado para aislar el test de UI del ciclo HTTP.
class _SeededVocabularyBloc extends VocabularyBloc {
  _SeededVocabularyBloc(List<VocabularyEntry> entries)
    : super(const _FakeVocabularyRepository()) {
    emit(VocabularyState(status: VocabularyStatus.success, entries: entries));
  }
}
