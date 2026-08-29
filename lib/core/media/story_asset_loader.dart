import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../auth/session_scoped_cache.dart';
import '../constants/app_messages.dart';
import '../network/api_client.dart';
import '../telemetry/security_event.dart';
import '../telemetry/security_telemetry.dart';

/// Descarga recursos de historias que la API entrega solo con sesión activa.
///
/// Guarda en memoria lo ya descargado, con un tope de tamaño y de cantidad: un
/// catálogo grande de historias, cada una con su portada, llenaría la memoria
/// del dispositivo hasta degradar o cerrar la aplicación. Cuando se pasa de
/// cualquiera de los dos topes se descarta lo menos usado recientemente.
class StoryAssetLoader implements SessionScopedCache {
  StoryAssetLoader(
    this._apiClient, {
    SecurityTelemetry? telemetry,
    int maxBytes = defaultMaxBytes,
    int maxEntries = defaultMaxEntries,
  }) : _telemetry = telemetry,
       _maxBytes = maxBytes,
       _maxEntries = maxEntries;

  /// Tope de memoria de la caché. Las portadas llegan optimizadas por la API.
  static const int defaultMaxBytes = 16 * 1024 * 1024;

  /// Tope de recursos guardados, para no acumular muchos aunque sean pequeños.
  static const int defaultMaxEntries = 50;

  final ApiClient _apiClient;
  final SecurityTelemetry? _telemetry;
  final int _maxBytes;
  final int _maxEntries;

  /// Orden de uso: el primero es el menos usado recientemente y sale primero.
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();
  final Map<String, Future<Uint8List>> _inFlight = {};
  int _usedBytes = 0;

  /// Memoria ocupada por la caché, para pruebas y diagnóstico.
  @visibleForTesting
  int get usedBytes => _usedBytes;

  /// Cantidad de recursos guardados, para pruebas y diagnóstico.
  @visibleForTesting
  int get entryCount => _cache.length;

  /// Reutiliza portadas ya descargadas y evita pedir dos veces el mismo id.
  Future<Uint8List> load(String assetId, {bool cache = true}) {
    final cached = _readFromCache(assetId);
    if (cached != null) return Future.value(cached);

    final pending = _inFlight[assetId];
    if (pending != null) return pending;

    final request = _download(assetId, cache: cache);
    _inFlight[assetId] = request;
    return request;
  }

  /// Libera las portadas guardadas al cerrar sesión o cambiar de usuario.
  @override
  void clear() {
    _cache.clear();
    _inFlight.clear();
    _usedBytes = 0;
  }

  /// Devuelve el recurso y lo marca como el más usado recientemente.
  Uint8List? _readFromCache(String assetId) {
    final bytes = _cache.remove(assetId);
    if (bytes == null) return null;

    // Reinsertar lo manda al final del orden, que es donde vive lo reciente.
    _cache[assetId] = bytes;
    return bytes;
  }

  void _store(String assetId, Uint8List bytes) {
    // Un recurso que por sí solo no cabe no se guarda: desalojaría todo lo
    // demás sin llegar a caber nunca.
    if (bytes.lengthInBytes > _maxBytes) return;

    final previous = _cache.remove(assetId);
    if (previous != null) _usedBytes -= previous.lengthInBytes;

    _cache[assetId] = bytes;
    _usedBytes += bytes.lengthInBytes;

    while (_cache.length > _maxEntries || _usedBytes > _maxBytes) {
      final oldest = _cache.keys.first;
      _usedBytes -= _cache.remove(oldest)!.lengthInBytes;
    }
  }

  Future<Uint8List> _download(String assetId, {required bool cache}) async {
    try {
      final bytes = await _apiClient.getBytes(
        '/files/story-assets/${Uri.encodeComponent(assetId)}',
      );
      if (cache) _store(assetId, bytes);
      return bytes;
    } catch (error) {
      // El identificador se sanea en la telemetria: registrar cual fue diria
      // que historia estaba leyendo esta persona.
      _telemetry?.record(
        SecurityEventType.assetLoadFailed,
        endpoint: '/files/story-assets/$assetId',
      );
      throw mapDioException(error, AppMessages.assetLoadError);
    } finally {
      _inFlight.remove(assetId);
    }
  }
}
