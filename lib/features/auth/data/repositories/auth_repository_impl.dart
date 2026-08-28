import '../../../../core/constants/app_messages.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/device_identity_service.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService secureStorage,
    required PreferencesService preferences,
    required DeviceIdentityService deviceIdentity,
  }) : _remoteDataSource = remoteDataSource,
       _secureStorage = secureStorage,
       _preferences = preferences,
       _deviceIdentity = deviceIdentity;

  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;
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
        'clientType': 'mobile',
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
    final accessToken = await _secureStorage.read(StorageKeys.accessToken);
    if (!hasFlag || accessToken == null) return null;

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
    final refreshToken = await _secureStorage.read(StorageKeys.refreshToken);
    try {
      await _remoteDataSource.logout({
        'clientType': 'mobile',
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
    await _secureStorage.write(StorageKeys.accessToken, session.accessToken);
    if (session.refreshToken != null) {
      await _secureStorage.write(
        StorageKeys.refreshToken,
        session.refreshToken!,
      );
    }
    await _preferences.setBool(StorageKeys.isLoggedIn, true);
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(StorageKeys.accessToken);
    await _secureStorage.delete(StorageKeys.refreshToken);
    await _preferences.setBool(StorageKeys.isLoggedIn, false);
  }
}
