import 'package:english_reader_app/core/constants/app_keys.dart';
import 'package:english_reader_app/features/reader/domain/entities/word_detail.dart';
import 'package:english_reader_app/features/reader/presentation/services/word_pronunciation_player.dart';
import 'package:english_reader_app/features/reader/presentation/widgets/word_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WordDetailSheet reproduce audio remoto cuando está disponible', (
    tester,
  ) async {
    final player = _FakePronunciationPlayer(
      result: const PronunciationPlaybackResult(
        PronunciationPlaybackSource.remoteAudio,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WordDetailSheet(
            word: _word,
            isSaving: false,
            onSave: () {},
            pronunciationPlayer: player,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Pronunciar hello'), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.wordPronunciationButton));
    await tester.pumpAndSettle();

    expect(player.playedWord, 'hello');
    expect(find.text('Reproduciendo audio de la palabra.'), findsOneWidget);
  });

  testWidgets('WordDetailSheet informa fallback TTS local', (tester) async {
    final player = _FakePronunciationPlayer(
      result: const PronunciationPlaybackResult(
        PronunciationPlaybackSource.localTts,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WordDetailSheet(
            word: _word,
            isSaving: false,
            onSave: () {},
            pronunciationPlayer: player,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(AppKeys.wordPronunciationButton));
    await tester.pumpAndSettle();

    expect(find.text('Usando voz del dispositivo.'), findsOneWidget);
  });
}

const _word = WordDetail(
  id: 'word-1',
  word: 'hello',
  normalizedWord: 'hello',
  language: 'en',
  translations: [
    WordTranslation(
      id: 'translation-1',
      targetLanguage: 'es',
      translation: 'hola',
    ),
  ],
  examples: [],
  pronunciations: [
    WordPronunciation(
      id: 'pron-1',
      audioUrl: 'https://cdn.example.com/hello.mp3',
    ),
  ],
  isSaved: false,
);

/// Reproductor fake para validar el modal sin depender de plugins nativos.
class _FakePronunciationPlayer implements WordPronunciationPlayer {
  _FakePronunciationPlayer({required this.result});

  final PronunciationPlaybackResult result;
  String? playedWord;

  @override
  Future<void> dispose() async {}

  @override
  Future<PronunciationPlaybackResult> play(WordDetail word) async {
    playedWord = word.word;
    return result;
  }
}
