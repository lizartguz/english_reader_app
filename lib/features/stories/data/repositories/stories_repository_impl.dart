import '../../../../core/constants/app_messages.dart';
import '../../../../core/network/api_client.dart';
import '../../../reader/domain/entities/reading_progress.dart';
import '../../domain/entities/story.dart';
import '../../domain/repositories/stories_repository.dart';
import '../datasources/stories_remote_datasource.dart';

class StoriesRepositoryImpl implements StoriesRepository {
  const StoriesRepositoryImpl({
    required StoriesRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final StoriesRemoteDataSource _remoteDataSource;

  @override
  Future<List<Story>> listStories() async {
    try {
      return await _remoteDataSource.listStories();
    } catch (error) {
      throw mapDioException(error, AppMessages.storiesLoadError);
    }
  }

  @override
  Future<List<ReadingProgress>> listReadingProgress() async {
    try {
      return await _remoteDataSource.listReadingProgress();
    } catch (error) {
      throw mapDioException(error, AppMessages.progressLoadError);
    }
  }

  @override
  Future<Story> getStory(String id) async {
    try {
      return await _remoteDataSource.getStory(id);
    } catch (error) {
      throw mapDioException(error, AppMessages.storyLoadError);
    }
  }
}
