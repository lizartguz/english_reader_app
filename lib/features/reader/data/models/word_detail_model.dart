import '../../domain/entities/word_detail.dart';

class WordDetailModel extends WordDetail {
  const WordDetailModel({
    required super.id,
    required super.word,
    required super.normalizedWord,
    required super.language,
    required super.translations,
    required super.examples,
    required super.pronunciations,
    required super.isSaved,
    super.phonetic,
    super.definitionEn,
    super.partOfSpeech,
    super.savedWordId,
  });

  factory WordDetailModel.fromJson(Map<String, dynamic> json) {
    return WordDetailModel(
      id: json['id'] as String,
      word: json['word'] as String? ?? '',
      normalizedWord: json['normalizedWord'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      phonetic: json['phonetic'] as String?,
      definitionEn: json['definitionEn'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      translations: (json['translations'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                WordTranslationModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      examples: (json['examples'] as List<dynamic>? ?? const [])
          .map(
            (item) => WordExampleModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      pronunciations: (json['pronunciations'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                WordPronunciationModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      isSaved: json['isSaved'] == true,
      savedWordId: json['savedWordId'] as String?,
    );
  }
}

class WordTranslationModel extends WordTranslation {
  const WordTranslationModel({
    required super.id,
    required super.targetLanguage,
    required super.translation,
    super.meaningContext,
  });

  factory WordTranslationModel.fromJson(Map<String, dynamic> json) {
    return WordTranslationModel(
      id: json['id'] as String,
      targetLanguage: json['targetLanguage'] as String? ?? 'es',
      translation: json['translation'] as String? ?? '',
      meaningContext: json['meaningContext'] as String?,
    );
  }
}

class WordExampleModel extends WordExample {
  const WordExampleModel({
    required super.id,
    required super.exampleText,
    required super.sortOrder,
  });

  factory WordExampleModel.fromJson(Map<String, dynamic> json) {
    return WordExampleModel(
      id: json['id'] as String,
      exampleText: json['exampleText'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class WordPronunciationModel extends WordPronunciation {
  const WordPronunciationModel({
    required super.id,
    super.accent,
    super.phonetic,
    super.audioUrl,
  });

  factory WordPronunciationModel.fromJson(Map<String, dynamic> json) {
    return WordPronunciationModel(
      id: json['id'] as String,
      accent: json['accent'] as String?,
      phonetic: json['phonetic'] as String?,
      audioUrl: json['audioUrl'] as String?,
    );
  }
}
