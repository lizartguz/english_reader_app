import '../constants/storage_keys.dart';
import '../storage/secure_storage_service.dart';
import 'auth_session_transport.dart';

/// Decide dónde vive cada token de sesión según la plataforma.
///
/// En Web `flutter_secure_storage` termina escribiendo en `localStorage`, que
/// cualquier XSS puede leer. Por eso allí el access token se guarda solo en
/// memoria y el refresh token no se guarda en absoluto: viaja en cookie
/// `HttpOnly`. En plataformas nativas ambos siguen en almacenamiento seguro,
/// que es respaldado por Keystore/Keychain.
class SessionTokenStore {
  SessionTokenStore({
    required AuthSessionTransport transport,
    required SecureStorageService secureStorage,
  }) : _transport = transport,
       _secureStorage = secureStorage;

  final AuthSessionTransport _transport;
  final SecureStorageService _secureStorage;

  String? _memoryAccessToken;

  /// En Web los tokens no tocan disco; se pierden a propósito al recargar.
  bool get keepsAccessTokenInMemory => _transport.usesCookieRefresh;

  Future<String?> readAccessToken() async {
    if (keepsAccessTokenInMemory) return _memoryAccessToken;
    return _secureStorage.read(StorageKeys.accessToken);
  }

  Future<void> writeAccessToken(String token) async {
    if (keepsAccessTokenInMemory) {
      _memoryAccessToken = token;
      // Purga un token de una versión anterior que sí lo persistía.
      await _secureStorage.delete(StorageKeys.accessToken);
      return;
    }
    await _secureStorage.write(StorageKeys.accessToken, token);
  }

  /// En Web siempre es `null`: el refresh token vive en la cookie del navegador.
  Future<String?> readRefreshToken() async {
    if (_transport.usesCookieRefresh) return null;
    return _secureStorage.read(StorageKeys.refreshToken);
  }

  Future<void> writeRefreshToken(String? token) async {
    if (_transport.usesCookieRefresh || token == null) {
      await _secureStorage.delete(StorageKeys.refreshToken);
      return;
    }
    await _secureStorage.write(StorageKeys.refreshToken, token);
  }

  /// Borra la sesión local. Se llama en logout y ante sesión inválida.
  Future<void> clear() async {
    _memoryAccessToken = null;
    await _secureStorage.delete(StorageKeys.accessToken);
    await _secureStorage.delete(StorageKeys.refreshToken);
  }
}
