import 'package:english_reader_app/core/constants/app_keys.dart';
import 'package:english_reader_app/features/stories/domain/entities/story.dart';
import 'package:english_reader_app/features/stories/domain/repositories/stories_repository.dart';
import 'package:english_reader_app/features/stories/presentation/bloc/stories_bloc.dart';
import 'package:english_reader_app/features/stories/presentation/pages/stories_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('StoriesPage usa lista en ancho móvil', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final bloc = StoriesBloc(_FakeStoriesRepository())
      ..add(const StoriesLoaded());
    addTearDown(bloc.close);

    await tester.pumpWidget(_TestApp(bloc: bloc));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.storiesList), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('StoriesPage usa grid en ancho Web o tablet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final bloc = StoriesBloc(_FakeStoriesRepository())
      ..add(const StoriesLoaded());
    addTearDown(bloc.close);

    await tester.pumpWidget(_TestApp(bloc: bloc));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.storiesList), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });
}

/// Contenedor mínimo para probar la pantalla sin navegación real.
class _TestApp extends StatelessWidget {
  const _TestApp({required this.bloc});

  final StoriesBloc bloc;

  /// Inyecta el BLoC de historias en un árbol Material.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider.value(value: bloc, child: const StoriesPage()),
    );
  }
}

/// Repositorio fake para entregar historias sin depender de la API.
class _FakeStoriesRepository implements StoriesRepository {
  @override
  Future<List<Story>> listStories() async => const [_story];

  @override
  Future<Story> getStory(String id) async => _story;
}

const _story = Story(
  id: 'story-1',
  title: 'A Responsive Story',
  slug: 'a-responsive-story',
  status: 'published',
  sortOrder: 1,
  readingLevel: StoryReadingLevel(id: 'level-1', code: 'A1', name: 'A1'),
  genres: [
    StoryGenre(id: 'genre-1', code: 'daily', name: 'Daily life'),
    StoryGenre(id: 'genre-2', code: 'travel', name: 'Travel'),
  ],
  assets: [],
  summary: 'A short story for responsive layout tests.',
  estimatedReadingMinutes: 4,
);
