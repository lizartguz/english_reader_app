import '../../../../core/network/api_client.dart';
import '../../../stories/data/models/story_model.dart';
import '../models/reading_progress_model.dart';
import '../models/word_detail_model.dart';

class ReaderRemoteDataSource {
  const ReaderRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<StoryModel> getStory(String storyId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/app/stories/${Uri.encodeComponent(storyId)}',
    );
    return StoryModel.fromJson(response.data!);
  }

  Future<WordDetailModel> lookupWord(String word) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/app/words/lookup',
      queryParameters: {'word': word, 'language': 'en', 'targetLanguage': 'es'},
    );
    return WordDetailModel.fromJson(response.data!);
  }

  Future<WordDetailModel> saveVocabulary({
    required String wordEntryId,
    required String storyId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/app/vocabulary',
      data: {'wordEntryId': wordEntryId, 'storyId': storyId},
    );
    final data = response.data!;
    return WordDetailModel.fromJson(data['word'] as Map<String, dynamic>);
  }

  Future<ReadingProgressModel?> getProgress(String storyId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/app/reading-progress/${Uri.encodeComponent(storyId)}',
    );
    if (response.data == null) return null;
    return ReadingProgressModel.fromJson(response.data!);
  }

  Future<ReadingProgressModel> saveProgress({
    required String storyId,
    required double progressPercent,
    String? lastPosition,
    bool? completed,
  }) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/app/reading-progress/${Uri.encodeComponent(storyId)}',
      data: {
        'progressPercent': progressPercent,
        if (lastPosition != null) 'lastPosition': lastPosition,
        if (completed != null) 'completed': completed,
      },
    );
    return ReadingProgressModel.fromJson(response.data!);
  }
}
