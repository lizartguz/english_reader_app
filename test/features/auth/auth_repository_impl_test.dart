import 'package:english_reader_app/core/auth/auth_session_transport.dart';
import 'package:english_reader_app/core/auth/session_restorer.dart';
import 'package:english_reader_app/core/auth/session_scoped_cache.dart';
import 'package:english_reader_app/core/auth/session_token_store.dart';
import 'package:english_reader_app/core/constants/storage_keys.dart';
import 'package:english_reader_app/core/storage/device_identity_service.dart';
import 'package:english_reader_app/core/storage/preferences_service.dart';
import 'package:english_reader_app/core/storage/secure_storage_service.dart';
import 'package:english_reader_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:english_reader_app/features/auth/data/models/auth_session_model.dart';
import 'package:english_reader_app/features/auth/data/models/auth_user_model.dart';
import 'package:english_reader_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRepositoryImpl', () {
    test('persiste access y refresh token en clientes móviles', () async {
      final remote = _FakeAuthRemoteDataSource(
        session: _session(refreshToken: 'refresh-token'),
      );
      final storage = _FakeSecureStorage();
      final preferences = _FakePreferencesService();
      final repository = _repository(
        remote: remote,
        storage: storage,
        preferences: preferences,
        transport: const AuthSessionTransport(isWeb: false),
      );

      await repository.login(email: 'lector@test.local', password: 'Clave123');

      expect(remote.lastLoginPayload?['clientType'], 'mobile');
      expect(storage.values[StorageKeys.accessToken], 'access-token');
      expect(storage.values[StorageKeys.refreshToken], 'refresh-token');
      expect(preferences.values[StorageKeys.isLoggedIn], isTrue);
    });

    test('usa app_web y no persiste refresh token en Flutter Web', () async {
      final remote = _FakeAuthRemoteDataSource(
        session: _session(refreshToken: null),
      );
      final storage = _FakeSecureStorage()
        ..values[StorageKeys.refreshToken] = 'refresh-local-antiguo';
      final preferences = _FakePreferencesService();
      final repository = _repository(
        remote: remote,
        storage: storage,
        preferences: preferences,
        transport: const AuthSessionTransport(isWeb: true),
      );

      await repository.login(email: 'lector@test.local', password: 'Clave123');

      expect(remote.lastLoginPayload?['clientType'], 'app_web');
      // Ningún token queda en disco: el access vive en memoria y el refresh
      // en la cookie HttpOnly que administra la API.
      expect(storage.values.containsKey(StorageKeys.accessToken), isFalse);
      expect(storage.values.containsKey(StorageKeys.refreshToken), isFalse);
      expect(preferences.values[StorageKeys.isLoggedIn], isTrue);
    });

    test('Web recupera la sesion con la cookie tras recargar la pagina', () async {
      final storage = _FakeSecureStorage();
      final preferences = _FakePreferencesService()
        ..values[StorageKeys.isLoggedIn] = true;
      const transport = AuthSessionTransport(isWeb: true);
      final tokenStore = SessionTokenStore(
        transport: transport,
        secureStorage: storage,
      );
      // Al recargar, el access token en memoria se pierde; el restaurador
      // simula la renovación con la cookie y devuelve uno nuevo.
      final restorer = _FakeSessionRestorer(
        onRestore: () => tokenStore.writeAccessToken('access-token-nuevo'),
      );
      final repository = _repository(
        remote: _FakeAuthRemoteDataSource(session: _session(refreshToken: null)),
        storage: storage,
        preferences: preferences,
        transport: transport,
        tokenStore: tokenStore,
        sessionRestorer: restorer,
      );

      final user = await repository.verifySession();

      expect(restorer.calls, 1);
      expect(user, isNotNull);
      expect(await tokenStore.readAccessToken(), 'access-token-nuevo');
    });

    test('Web cierra la sesion si la cookie ya no sirve', () async {
      final storage = _FakeSecureStorage();
      final preferences = _FakePreferencesService()
        ..values[StorageKeys.isLoggedIn] = true;
      final restorer = _FakeSessionRestorer(succeeds: false);
      final repository = _repository(
        remote: _FakeAuthRemoteDataSource(session: _session(refreshToken: null)),
        storage: storage,
        preferences: preferences,
        transport: const AuthSessionTransport(isWeb: true),
        sessionRestorer: restorer,
      );

      expect(await repository.verifySession(), isNull);
      expect(restorer.calls, 1);
      expect(preferences.values[StorageKeys.isLoggedIn], isFalse);
    });

    test('vacia las caches privadas al cerrar sesion', () async {
      final cache = _FakeSessionScopedCache();
      final repository = _repository(
        remote: _FakeAuthRemoteDataSource(
          session: _session(refreshToken: 'refresh-token'),
        ),
        storage: _FakeSecureStorage(),
        preferences: _FakePreferencesService(),
        transport: const AuthSessionTransport(isWeb: false),
        sessionCaches: [cache],
      );

      await repository.logout();

      expect(cache.clears, 1);
    });

    test('vacia las caches privadas al iniciar sesion con otra cuenta', () async {
      final cache = _FakeSessionScopedCache();
      final repository = _repository(
        remote: _FakeAuthRemoteDataSource(
          session: _session(refreshToken: 'refresh-token'),
        ),
        storage: _FakeSecureStorage(),
        preferences: _FakePreferencesService(),
        transport: const AuthSessionTransport(isWeb: false),
        sessionCaches: [cache],
      );

      await repository.login(email: 'otro@test.local', password: 'Clave123');

      expect(cache.clears, 1);
    });

    test('vacia las caches privadas cuando la sesion ya no es valida', () async {
      final cache = _FakeSessionScopedCache();
      final repository = _repository(
        remote: _FakeAuthRemoteDataSource(session: _session(refreshToken: null)),
        storage: _FakeSecureStorage(),
        preferences: _FakePreferencesService()
          ..values[StorageKeys.isLoggedIn] = true,
        transport: const AuthSessionTransport(isWeb: true),
        sessionRestorer: _FakeSessionRestorer(succeeds: false),
        sessionCaches: [cache],
      );

      // Este cierre no pasa por el bloc de autenticación: si la limpieza
      // dependiera de él, los recursos privados quedarían en memoria.
      expect(await repository.verifySession(), isNull);
      expect(cache.clears, 1);
    });

    test('logout Web no envia refresh token por cuerpo', () async {
      final remote = _FakeAuthRemoteDataSource(
        session: _session(refreshToken: null),
      );
      final storage = _FakeSecureStorage()
        ..values[StorageKeys.refreshToken] = 'refresh-local-antiguo';
      final repository = _repository(
        remote: remote,
        storage: storage,
        preferences: _FakePreferencesService(),
        transport: const AuthSessionTransport(isWeb: true),
      );

      await repository.logout();

      expect(remote.lastLogoutPayload?['clientType'], 'app_web');
      expect(remote.lastLogoutPayload?.containsKey('refreshToken'), isFalse);
      expect(storage.values.containsKey(StorageKeys.refreshToken), isFalse);
    });
  });
}

AuthRepositoryImpl _repository({
  required _FakeAuthRemoteDataSource remote,
  required _FakeSecureStorage storage,
  required _FakePreferencesService preferences,
  required AuthSessionTransport transport,
  SessionTokenStore? tokenStore,
  _FakeSessionRestorer? sessionRestorer,
  List<SessionScopedCache> sessionCaches = const [],
}) {
  return AuthRepositoryImpl(
    remoteDataSource: remote,
    authSessionTransport: transport,
    tokenStore:
        tokenStore ??
        SessionTokenStore(transport: transport, secureStorage: storage),
    sessionRestorer: sessionRestorer ?? _FakeSessionRestorer(),
    sessionCaches: sessionCaches,
    preferences: preferences,
    deviceIdentity: _FakeDeviceIdentityService(),
  );
}

AuthSessionModel _session({required String? refreshToken}) {
  return AuthSessionModel(
    accessToken: 'access-token',
    refreshToken: refreshToken,
    tokenType: 'Bearer',
    expiresIn: 900,
    sessionExpiresAt: DateTime.utc(2026, 8, 28).add(const Duration(days: 1)),
    user: const AuthUserModel(
      id: 'user-id',
      email: 'lector@test.local',
      firstName: 'Lector',
      lastName: 'Demo',
      fullName: 'Lector Demo',
      status: 'active',
      roles: ['CLIENT'],
      permissions: [],
    ),
  );
}

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  _FakeAuthRemoteDataSource({required this.session});

  final AuthSessionModel session;
  Map<String, dynamic>? lastLoginPayload;
  Map<String, dynamic>? lastLogoutPayload;

  @override
  Future<AuthSessionModel> login(Map<String, dynamic> payload) async {
    lastLoginPayload = payload;
    return session;
  }

  @override
  Future<void> logout(Map<String, dynamic> payload) async {
    lastLogoutPayload = payload;
  }

  @override
  Future<String> forgotPassword(String email) async => 'ok';

  @override
  Future<String> register(Map<String, dynamic> payload) async => 'ok';

  @override
  Future<String> resetPassword({
    required String token,
    required String password,
  }) async => 'ok';

  @override
  Future<AuthUserModel> verifySession() async => session.user as AuthUserModel;
}

class _FakeSecureStorage implements SecureStorageService {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class _FakePreferencesService implements PreferencesService {
  final values = <String, Object>{};

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    return values[key] as bool? ?? defaultValue;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    values[key] = value;
  }

  @override
  double getDouble(String key, {required double defaultValue}) {
    return values[key] as double? ?? defaultValue;
  }

  @override
  Future<void> setDouble(String key, double value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

class _FakeDeviceIdentityService implements DeviceIdentityService {
  @override
  Future<Map<String, String>> devicePayload() async {
    return {'deviceId': 'device-id', 'platform': 'test', 'appVersion': '0.1.0'};
  }

  @override
  Future<String> getOrCreateDeviceId() async => 'device-id';
}

class _FakeSessionRestorer implements SessionRestorer {
  _FakeSessionRestorer({this.succeeds = true, this.onRestore});

  final bool succeeds;
  final Future<void> Function()? onRestore;
  int calls = 0;

  @override
  Future<bool> restoreSession() async {
    calls += 1;
    if (!succeeds) return false;
    await onRestore?.call();
    return true;
  }
}

class _FakeSessionScopedCache implements SessionScopedCache {
  int clears = 0;

  @override
  void clear() {
    clears += 1;
  }
}
