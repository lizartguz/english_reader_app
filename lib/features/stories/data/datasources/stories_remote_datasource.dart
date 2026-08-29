import '../../../../core/network/api_client.dart';
import '../../../../core/network/payload_guard.dart';
import '../../../reader/data/models/reading_progress_model.dart';
import '../models/story_model.dart';

class StoriesRemoteDataSource {
  const StoriesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<StoryModel>> listStories({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/app/stories',
      queryParameters: {'page': page, 'limit': limit},
    );
    return parseApiPayload(
      () => response
          .requireData()
          .map((item) => StoryModel.fromJson(requirePayloadMap(item)))
          .toList(),
    );
  }

  /// Trae el avance del usuario para pintar progreso en el listado.
  Future<List<ReadingProgressModel>> listReadingProgress() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/app/reading-progress',
    );
    return parseApiPayload(
      () => response
          .requireData()
          .map((item) => ReadingProgressModel.fromJson(requirePayloadMap(item)))
          .toList(),
    );
  }

  Future<StoryModel> getStory(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/app/stories/${Uri.encodeComponent(id)}',
    );
    return parseApiPayload(() => StoryModel.fromJson(response.requireData()));
  }
}
