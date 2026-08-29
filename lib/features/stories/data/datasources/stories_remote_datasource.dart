import '../../../../core/network/api_client.dart';
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
    return (response.data ?? const [])
        .map((item) => StoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Trae el avance del usuario para pintar progreso en el listado.
  Future<List<ReadingProgressModel>> listReadingProgress() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/app/reading-progress',
    );
    return (response.data ?? const [])
        .map(
          (item) => ReadingProgressModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<StoryModel> getStory(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/app/stories/${Uri.encodeComponent(id)}',
    );
    return StoryModel.fromJson(response.data!);
  }
}
