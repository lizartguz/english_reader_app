import '../../../../core/network/api_client.dart';
import '../models/vocabulary_entry_model.dart';

/// Data source HTTP para `/app/vocabulary`.
class VocabularyRemoteDataSource {
  const VocabularyRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// Consulta el vocabulario personal paginado desde la API.
  Future<List<VocabularyEntryModel>> listVocabulary({
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/app/vocabulary',
      queryParameters: {'page': page, 'limit': limit},
    );

    return (response.data ?? const [])
        .map(
          (item) => VocabularyEntryModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  /// Envía cambios editables de estado o notas al backend.
  Future<VocabularyEntryModel> updateVocabulary({
    required String id,
    String? status,
    String? notes,
  }) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/app/vocabulary/${Uri.encodeComponent(id)}',
      data: {
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
      },
    );

    return VocabularyEntryModel.fromJson(response.data!);
  }

  /// Elimina el registro guardado sin borrar la palabra del diccionario.
  Future<void> deleteVocabulary(String id) async {
    await _apiClient.delete<Map<String, dynamic>>(
      '/app/vocabulary/${Uri.encodeComponent(id)}',
    );
  }
}
