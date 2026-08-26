import 'package:english_reader_app/features/stories/domain/entities/story.dart';
import 'package:english_reader_app/features/stories/presentation/widgets/story_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StoryCard expone una acción semántica completa', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryCard(story: _story, onTap: () {}),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Abrir historia A Semantics Story, nivel Principiante, duración aproximada 5 minutos',
      ),
      findsOneWidget,
    );
  });
}

const _story = Story(
  id: 'story-1',
  title: 'A Semantics Story',
  slug: 'a-semantics-story',
  status: 'published',
  sortOrder: 1,
  readingLevel: StoryReadingLevel(
    id: 'level-1',
    code: 'A1',
    name: 'Principiante',
  ),
  genres: [StoryGenre(id: 'genre-1', code: 'daily', name: 'Daily life')],
  assets: [],
  summary: 'A short story for accessibility tests.',
  estimatedReadingMinutes: 5,
);
