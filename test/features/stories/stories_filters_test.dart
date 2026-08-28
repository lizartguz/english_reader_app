import 'package:english_reader_app/core/constants/app_keys.dart';
import 'package:english_reader_app/features/reader/domain/entities/reading_progress.dart';
import 'package:english_reader_app/features/stories/domain/entities/story.dart';
import 'package:english_reader_app/features/stories/domain/repositories/stories_repository.dart';
import 'package:english_reader_app/features/stories/presentation/bloc/stories_bloc.dart';
import 'package:english_reader_app/features/stories/presentation/pages/stories_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('La búsqueda deja solo las historias que coinciden', (
    tester,
  ) async {
    await _pumpStories(tester);

    expect(find.text('A Rainy Day'), findsOneWidget);
    expect(find.text('Trip to Madrid'), findsOneWidget);

    await tester.enterText(find.byKey(AppKeys.storiesSearchField), 'madrid');
    await tester.pumpAndSettle();

    expect(find.text('Trip to Madrid'), findsOneWidget);
    expect(find.text('A Rainy Day'), findsNothing);
    expect(find.text('1 historia de 2'), findsOneWidget);
  });

  testWidgets('El chip de nivel filtra el catálogo cargado', (tester) async {
    await _pumpStories(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Intermedio'));
    await tester.pumpAndSettle();

    expect(find.text('Trip to Madrid'), findsOneWidget);
    expect(find.text('A Rainy Day'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Todas'));
    await tester.pumpAndSettle();

    expect(find.text('A Rainy Day'), findsOneWidget);
  });

  testWidgets('La tarjeta muestra el avance guardado de la historia', (
    tester,
  ) async {
    await _pumpStories(tester);

    expect(find.text('Continuar · 42%'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('avance 42 por ciento')),
      findsOneWidget,
    );
  });

  testWidgets('Sin coincidencias ofrece quitar los filtros aplicados', (
    tester,
  ) async {
    await _pumpStories(tester);

    await tester.enterText(find.byKey(AppKeys.storiesSearchField), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text('Sin coincidencias'), findsOneWidget);

    await tester.tap(find.text('Quitar filtros'));
    await tester.pumpAndSettle();

    expect(find.text('Sin coincidencias'), findsNothing);
    expect(find.text('A Rainy Day'), findsOneWidget);
  });
}

/// Monta la pantalla con dos historias de niveles distintos.
Future<void> _pumpStories(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final bloc = StoriesBloc(_FakeStoriesRepository())
    ..add(const StoriesLoaded());
  addTearDown(bloc.close);

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(value: bloc, child: const StoriesPage()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Repositorio fake con niveles distintos para ejercitar los filtros.
class _FakeStoriesRepository implements StoriesRepository {
  @override
  Future<List<Story>> listStories() async => _stories;

  @override
  Future<List<ReadingProgress>> listReadingProgress() async => const [
    ReadingProgress(
      id: 'progress-1',
      userId: 'user-1',
      storyId: 'story-1',
      progressPercent: 42,
    ),
  ];

  @override
  Future<Story> getStory(String id) async => _stories.first;
}

const _stories = [
  Story(
    id: 'story-1',
    title: 'A Rainy Day',
    slug: 'a-rainy-day',
    status: 'published',
    sortOrder: 1,
    readingLevel: StoryReadingLevel(id: 'a1', code: 'A1', name: 'Principiante'),
    genres: [StoryGenre(id: 'genre-1', code: 'daily', name: 'Daily life')],
    assets: [],
    summary: 'Mia walks under the rain.',
    estimatedReadingMinutes: 3,
  ),
  Story(
    id: 'story-2',
    title: 'Trip to Madrid',
    slug: 'trip-to-madrid',
    status: 'published',
    sortOrder: 2,
    readingLevel: StoryReadingLevel(id: 'b1', code: 'B1', name: 'Intermedio'),
    genres: [StoryGenre(id: 'genre-2', code: 'travel', name: 'Travel')],
    assets: [],
    summary: 'A weekend in Spain.',
    estimatedReadingMinutes: 6,
  ),
];
