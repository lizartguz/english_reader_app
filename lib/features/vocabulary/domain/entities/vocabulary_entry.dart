import 'package:equatable/equatable.dart';

import '../../../reader/domain/entities/word_detail.dart';

class VocabularyEntry extends Equatable {
  const VocabularyEntry({
    required this.id,
    required this.status,
    required this.savedAt,
    required this.word,
    this.notes,
    this.storyTitle,
  });

  final String id;
  final String status;
  final String? notes;
  final DateTime savedAt;
  final WordDetail word;
  final String? storyTitle;

  @override
  List<Object?> get props => [id, status, notes, savedAt, word, storyTitle];
}
