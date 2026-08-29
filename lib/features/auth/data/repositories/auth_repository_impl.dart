import '../../../../core/constants/app_messages.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/auth/auth_session_transport.dart';
import '../../../../core/auth/session_restorer.dart';
import '../../../../core/auth/session_scoped_cache.dart';
import '../../../../core/auth/session_token_store.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/device_identity_service.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthSessionTransport authSessionTransport,
    required SessionTokenStore tokenStore,
    required SessionRestorer sessionRestorer,
    required List<SessionScopedCache> sessionCaches,
    required PreferencesService preferences,
    required DeviceIdentityService deviceIdentity,
  }) : _remoteDataSource = remoteDataSource,
       _authSessionTransport = authSessionTransport,
       _tokenStore = tokenStore,
       _sessionRestorer = sessionRestorer,
       _sessionCaches = sessionCaches,
       _preferences = preferences,
       _deviceIdentity = deviceIdentity;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthSessionTransport _authSessionTransport;
  final SessionTokenStore _tokenStore;
  final SessionRestorer _sessionRestorer;
  final List<SessionScopedCache> _sessionCaches;
  final PreferencesService _preferences;
  final DeviceIdentityService _deviceIdentity;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _remoteDataSource.login({
        'email': email,
        'password': password,
        'clientType': _authSessionTransport.clientType,
        'device': await _deviceIdentity.devicePayload(),
      });
      await _persistSession(session);
      return session;
    } catch (error) {
      throw mapDioException(error, 'No se pudo iniciar sesión.');
    }
  }

  @override
  Future<String> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      return await _remoteDataSource.register({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
    } catch (error) {
      throw mapDioException(error, AppMessages.registerError);
    }
  }

  @override
  Future<String> requestPasswordReset(String email) async {
    try {
      return await _remoteDataSource.forgotPassword(email);
    } catch (error) {
      throw mapDioException(error, AppMessages.passwordResetError);
    }
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      return await _remoteDataSource.resetPassword(
        token: token,
        password: password,
      );
    } catch (error) {
      throw mapDioException(error, AppMessages.passwordResetError);
    }
  }

  @override
  Future<AuthUser?> verifySession() async {
    final hasFlag = await hasLocalSession();
    if (!hasFlag) return null;

    var accessToken = await _tokenStore.readAccessToken();
    if (accessToken == null && _tokenStore.keepsAccessTokenInMemory) {
      // Recarga de página en Web: el token en memoria se perdió, pero la cookie
      // de refresco sigue viva y puede devolver la sesión sin pedir credenciales.
      if (await _sessionRestorer.restoreSession()) {
        accessToken = await _tokenStore.readAccessToken();
      }
    }
    if (accessToken == null) {
      await clearSession();
      return null;
    }

    try {
      return _remoteDataSource.verifySession();
    } catch (error) {
      final exception = mapDioException(error, AppMessages.sessionExpired);
      await clearSession();
      throw exception;
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    try {
      await _remoteDataSource.logout({
        'clientType': _authSessionTransport.clientType,
        if (refreshToken != null) 'refreshToken': refreshToken,
      });
    } catch (_) {
      // La sesión local debe limpiarse aunque la API no responda al cerrar.
    } finally {
      await clearSession();
    }
  }

  @override
  Future<bool> hasLocalSession() async {
    return _preferences.getBool(StorageKeys.isLoggedIn);
  }

  Future<void> _persistSession(AuthSession session) async {
    // Otra cuenta puede iniciar sesión en el mismo proceso: lo descargado por
    // la anterior no debe quedar accesible.
    _clearSessionCaches();
    await _tokenStore.writeAccessToken(session.accessToken);
    // En Web `refreshToken` llega nulo: queda en la cookie HttpOnly de la API.
    await _tokenStore.writeRefreshToken(session.refreshToken);
    await _preferences.setBool(StorageKeys.isLoggedIn, true);
  }

  void _clearSessionCaches() {
    for (final cache in _sessionCaches) {
      cache.clear();
    }
  }

  Future<void> clearSession() async {
    // Se hace aquí y no en el bloc porque hay cierres que no pasan por él:
    // una sesión invalidada desde otro dispositivo o una cookie ya vencida.
    _clearSessionCaches();
    await _tokenStore.clear();
    await _preferences.setBool(StorageKeys.isLoggedIn, false);
  }
}
