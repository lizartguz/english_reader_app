import '../../../../core/constants/app_messages.dart';
import '../../../../core/network/api_client.dart';
import '../../../stories/domain/entities/story.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/entities/word_detail.dart';
import '../../domain/repositories/reader_repository.dart';
import '../datasources/reader_remote_datasource.dart';

class ReaderRepositoryImpl implements ReaderRepository {
  const ReaderRepositoryImpl({required ReaderRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final ReaderRemoteDataSource _remoteDataSource;

  @override
  Future<Story> getStory(String storyId) async {
    try {
      return _remoteDataSource.getStory(storyId);
    } catch (error) {
      throw mapDioException(error, AppMessages.storyLoadError);
    }
  }

  @override
  Future<WordDetail> lookupWord(String word) async {
    try {
      return _remoteDataSource.lookupWord(word);
    } catch (error) {
      throw mapDioException(error, AppMessages.wordLookupError);
    }
  }

  @override
  Future<WordDetail> saveVocabulary({
    required String wordEntryId,
    required String storyId,
  }) async {
    try {
      return _remoteDataSource.saveVocabulary(
        wordEntryId: wordEntryId,
        storyId: storyId,
      );
    } catch (error) {
      throw mapDioException(error, AppMessages.genericError);
    }
  }

  @override
  Future<ReadingProgress?> getProgress(String storyId) async {
    try {
      return _remoteDataSource.getProgress(storyId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ReadingProgress> saveProgress({
    required String storyId,
    required double progressPercent,
    String? lastPosition,
    bool? completed,
  }) async {
    try {
      return _remoteDataSource.saveProgress(
        storyId: storyId,
        progressPercent: progressPercent,
        lastPosition: lastPosition,
        completed: completed,
      );
    } catch (error) {
      throw mapDioException(error, AppMessages.genericError);
    }
  }
}
