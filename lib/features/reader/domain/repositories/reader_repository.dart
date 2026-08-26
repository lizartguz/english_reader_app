import '../../../stories/domain/entities/story.dart';
import '../entities/reading_progress.dart';
import '../entities/word_detail.dart';

abstract class ReaderRepository {
  Future<Story> getStory(String storyId);

  Future<WordDetail> lookupWord(String word);

  Future<WordDetail> saveVocabulary({
    required String wordEntryId,
    required String storyId,
  });

  Future<ReadingProgress?> getProgress(String storyId);

  Future<ReadingProgress> saveProgress({
    required String storyId,
    required double progressPercent,
    String? lastPosition,
    bool? completed,
  });
}
