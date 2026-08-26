import '../../../../core/network/api_client.dart';
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

  Future<StoryModel> getStory(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/app/stories/$id',
    );
    return StoryModel.fromJson(response.data!);
  }
}
