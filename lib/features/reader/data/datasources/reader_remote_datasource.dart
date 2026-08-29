import '../../../../core/network/api_client.dart';
import '../../../../core/network/payload_guard.dart';
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
    return parseApiPayload(() => StoryModel.fromJson(response.requireData()));
  }

  Future<WordDetailModel> lookupWord(String word) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/app/words/lookup',
      queryParameters: {'word': word, 'language': 'en', 'targetLanguage': 'es'},
    );
    return parseApiPayload(
      () => WordDetailModel.fromJson(response.requireData()),
    );
  }

  Future<WordDetailModel> saveVocabulary({
    required String wordEntryId,
    required String storyId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/app/vocabulary',
      data: {'wordEntryId': wordEntryId, 'storyId': storyId},
    );
    return parseApiPayload(() {
      final data = response.requireData();
      return WordDetailModel.fromJson(requirePayloadMapField(data, 'word'));
    });
  }

  Future<ReadingProgressModel?> getProgress(String storyId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/app/reading-progress/${Uri.encodeComponent(storyId)}',
    );
    return parseApiPayload(() {
      final data = response.data;
      if (data == null) return null;
      return ReadingProgressModel.fromJson(data);
    });
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
    return parseApiPayload(
      () => ReadingProgressModel.fromJson(response.requireData()),
    );
  }
}
