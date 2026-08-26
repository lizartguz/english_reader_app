import 'package:equatable/equatable.dart';

class WordDetail extends Equatable {
  const WordDetail({
    required this.id,
    required this.word,
    required this.normalizedWord,
    required this.language,
    required this.translations,
    required this.examples,
    required this.pronunciations,
    required this.isSaved,
    this.phonetic,
    this.definitionEn,
    this.partOfSpeech,
    this.savedWordId,
  });

  final String id;
  final String word;
  final String normalizedWord;
  final String language;
  final String? phonetic;
  final String? definitionEn;
  final String? partOfSpeech;
  final List<WordTranslation> translations;
  final List<WordExample> examples;
  final List<WordPronunciation> pronunciations;
  final bool isSaved;
  final String? savedWordId;

  String? get primaryTranslation {
    if (translations.isEmpty) return null;
    return translations.first.translation;
  }

  /// Prioriza el primer audio remoto válido entregado por la API.
  String? get preferredAudioUrl {
    for (final pronunciation in pronunciations) {
      final audioUrl = pronunciation.audioUrl?.trim();
      if (audioUrl != null && audioUrl.isNotEmpty) return audioUrl;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    word,
    normalizedWord,
    language,
    phonetic,
    definitionEn,
    partOfSpeech,
    translations,
    examples,
    pronunciations,
    isSaved,
    savedWordId,
  ];
}

class WordTranslation extends Equatable {
  const WordTranslation({
    required this.id,
    required this.targetLanguage,
    required this.translation,
    this.meaningContext,
  });

  final String id;
  final String targetLanguage;
  final String translation;
  final String? meaningContext;

  @override
  List<Object?> get props => [id, targetLanguage, translation, meaningContext];
}

class WordExample extends Equatable {
  const WordExample({
    required this.id,
    required this.exampleText,
    required this.sortOrder,
  });

  final String id;
  final String exampleText;
  final int sortOrder;

  @override
  List<Object?> get props => [id, exampleText, sortOrder];
}

class WordPronunciation extends Equatable {
  const WordPronunciation({
    required this.id,
    this.accent,
    this.phonetic,
    this.audioUrl,
  });

  final String id;
  final String? accent;
  final String? phonetic;
  final String? audioUrl;

  @override
  List<Object?> get props => [id, accent, phonetic, audioUrl];
}
