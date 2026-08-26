import 'package:english_reader_app/features/reader/domain/entities/word_detail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WordDetail usa el primer audio remoto válido', () {
    const word = WordDetail(
      id: 'word-1',
      word: 'hello',
      normalizedWord: 'hello',
      language: 'en',
      translations: [],
      examples: [],
      pronunciations: [
        WordPronunciation(id: 'pron-1', audioUrl: '  '),
        WordPronunciation(
          id: 'pron-2',
          audioUrl: 'https://cdn.example.com/hello.mp3',
        ),
      ],
      isSaved: false,
    );

    expect(word.preferredAudioUrl, 'https://cdn.example.com/hello.mp3');
  });
}
