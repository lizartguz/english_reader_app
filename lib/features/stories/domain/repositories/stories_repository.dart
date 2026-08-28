import '../../../reader/domain/entities/reading_progress.dart';
import '../entities/story.dart';

abstract class StoriesRepository {
  Future<List<Story>> listStories();

  Future<List<ReadingProgress>> listReadingProgress();

  Future<Story> getStory(String id);
}
