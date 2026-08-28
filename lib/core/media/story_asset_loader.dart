import 'dart:typed_data';

import '../constants/app_messages.dart';
import '../network/api_client.dart';

/// Descarga recursos de historias que la API entrega solo con sesión activa.
class StoryAssetLoader {
  StoryAssetLoader(this._apiClient);

  final ApiClient _apiClient;
  final Map<String, Uint8List> _cache = {};
  final Map<String, Future<Uint8List>> _inFlight = {};

  /// Reutiliza portadas ya descargadas y evita pedir dos veces el mismo id.
  Future<Uint8List> load(String assetId, {bool cache = true}) {
    final cached = _cache[assetId];
    if (cached != null) return Future.value(cached);

    final pending = _inFlight[assetId];
    if (pending != null) return pending;

    final request = _download(assetId, cache: cache);
    _inFlight[assetId] = request;
    return request;
  }

  /// Libera las portadas guardadas al cerrar sesión o cambiar de usuario.
  void clear() {
    _cache.clear();
    _inFlight.clear();
  }

  Future<Uint8List> _download(String assetId, {required bool cache}) async {
    try {
      final bytes = await _apiClient.getBytes('/files/story-assets/$assetId');
      if (cache) _cache[assetId] = bytes;
      return bytes;
    } catch (error) {
      throw mapDioException(error, AppMessages.assetLoadError);
    } finally {
      _inFlight.remove(assetId);
    }
  }
}
