import 'package:english_reader_app/core/constants/app_keys.dart';
import 'package:english_reader_app/features/reader/domain/entities/word_detail.dart';
import 'package:english_reader_app/features/vocabulary/domain/entities/vocabulary_entry.dart';
import 'package:english_reader_app/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:english_reader_app/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:english_reader_app/features/vocabulary/presentation/pages/vocabulary_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('La búsqueda filtra por palabra o traducción', (tester) async {
    await _pumpVocabulary(tester);

    await tester.enterText(find.byKey(AppKeys.vocabularySearchField), 'lluvia');
    await tester.pumpAndSettle();

    expect(find.text('umbrella'), findsOneWidget);
    expect(find.text('beautiful'), findsNothing);
    expect(find.text('1 palabra de 2'), findsOneWidget);
  });

  testWidgets('El chip de estado deja solo las palabras de ese estado', (
    tester,
  ) async {
    await _pumpVocabulary(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Aprendida'));
    await tester.pumpAndSettle();

    expect(find.text('beautiful'), findsOneWidget);
    expect(find.text('umbrella'), findsNothing);
  });

  testWidgets('Sin coincidencias permite quitar los filtros', (tester) async {
    await _pumpVocabulary(tester);

    await tester.enterText(find.byKey(AppKeys.vocabularySearchField), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text('Sin coincidencias'), findsOneWidget);

    await tester.tap(find.text('Quitar filtros'));
    await tester.pumpAndSettle();

    expect(find.text('umbrella'), findsOneWidget);
    expect(find.text('beautiful'), findsOneWidget);
  });
}

/// Monta el vocabulario con dos palabras en estados distintos.
Future<void> _pumpVocabulary(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final bloc = _SeededVocabularyBloc(_entries);
  addTearDown(bloc.close);

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<VocabularyBloc>.value(
        value: bloc,
        child: const VocabularyPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _entries = [
  _entry(
    id: 'saved-1',
    word: 'umbrella',
    translation: 'paraguas',
    status: 'saved',
    notes: 'Se usa cuando cae lluvia.',
  ),
  _entry(
    id: 'saved-2',
    word: 'beautiful',
    translation: 'hermoso',
    status: 'learned',
  ),
];

/// Construye una entrada de vocabulario mínima para los filtros.
VocabularyEntry _entry({
  required String id,
  required String word,
  required String translation,
  required String status,
  String? notes,
}) {
  return VocabularyEntry(
    id: id,
    status: status,
    notes: notes,
    savedAt: DateTime(2026),
    word: WordDetail(
      id: 'word-$id',
      word: word,
      normalizedWord: word,
      language: 'en',
      translations: [
        WordTranslation(
          id: 'translation-$id',
          targetLanguage: 'es',
          translation: translation,
        ),
      ],
      examples: const [],
      pronunciations: const [],
      isSaved: true,
      savedWordId: id,
    ),
  );
}

/// Repositorio fake mínimo para renderizar el vocabulario cargado.
class _FakeVocabularyRepository implements VocabularyRepository {
  const _FakeVocabularyRepository();

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

/// BLoC con estado cargado para aislar la UI del ciclo HTTP.
class _SeededVocabularyBloc extends VocabularyBloc {
  _SeededVocabularyBloc(List<VocabularyEntry> entries)
    : super(const _FakeVocabularyRepository()) {
    emit(VocabularyState(status: VocabularyStatus.success, entries: entries));
  }
}
