import '../entities/story.dart';

abstract class StoriesRepository {
  Future<List<Story>> listStories();

  Future<Story> getStory(String id);
}
