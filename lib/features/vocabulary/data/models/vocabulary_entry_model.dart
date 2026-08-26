import '../../../reader/data/models/word_detail_model.dart';
import '../../domain/entities/vocabulary_entry.dart';

class VocabularyEntryModel extends VocabularyEntry {
  const VocabularyEntryModel({
    required super.id,
    required super.status,
    required super.savedAt,
    required super.word,
    super.notes,
    super.storyTitle,
  });

  factory VocabularyEntryModel.fromJson(Map<String, dynamic> json) {
    final story = json['story'] as Map<String, dynamic>?;

    return VocabularyEntryModel(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'saved',
      notes: json['notes'] as String?,
      savedAt: DateTime.parse(json['savedAt'] as String),
      word: WordDetailModel.fromJson(json['word'] as Map<String, dynamic>),
      storyTitle: story?['title'] as String?,
    );
  }
}
