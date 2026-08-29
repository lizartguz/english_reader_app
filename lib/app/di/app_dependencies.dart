import '../../core/media/story_asset_loader.dart';
import '../../core/auth/auth_session_transport.dart';
import '../../core/auth/session_token_store.dart';
import '../../core/telemetry/security_telemetry.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/device_identity_service.dart';
import '../../core/storage/preferences_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/reader/data/datasources/reader_remote_datasource.dart';
import '../../features/reader/data/repositories/reader_repository_impl.dart';
import '../../features/reader/domain/repositories/reader_repository.dart';
import '../../features/stories/data/datasources/stories_remote_datasource.dart';
import '../../features/stories/data/repositories/stories_repository_impl.dart';
import '../../features/stories/domain/repositories/stories_repository.dart';
import '../../features/vocabulary/data/datasources/vocabulary_remote_datasource.dart';
import '../../features/vocabulary/data/repositories/vocabulary_repository_impl.dart';
import '../../features/vocabulary/domain/repositories/vocabulary_repository.dart';
import '../config/app_config.dart';

/// Dependencias raiz de la aplicacion.
class AppDependencies {
  const AppDependencies({
    required this.config,
    required this.secureStorage,
    required this.preferences,
    required this.deviceIdentity,
    required this.apiClient,
    required this.storyAssetLoader,
    required this.authRepository,
    required this.storiesRepository,
    required this.readerRepository,
    required this.vocabularyRepository,
  });

  final AppConfig config;
  final SecureStorageService secureStorage;
  final PreferencesService preferences;
  final DeviceIdentityService deviceIdentity;
  final ApiClient apiClient;
  final StoryAssetLoader storyAssetLoader;
  final AuthRepository authRepository;
  final StoriesRepository storiesRepository;
  final ReaderRepository readerRepository;
  final VocabularyRepository vocabularyRepository;

  static Future<AppDependencies> create() async {
    final config = AppConfig.fromEnvironment();
    final authSessionTransport = const AuthSessionTransport();
    final secureStorage = SecureStorageService();
    // Concentra dónde vive cada token: memoria en Web, almacenamiento seguro
    // en nativo. Lo comparten el cliente HTTP y el repositorio de auth.
    final tokenStore = SessionTokenStore(
      transport: authSessionTransport,
      secureStorage: secureStorage,
    );
    final preferences = await PreferencesService.create();
    final deviceIdentity = DeviceIdentityService(
      secureStorage: secureStorage,
      config: config,
    );
    // Canal unico de incidencias de seguridad: lo comparten el cliente HTTP y
    // el cargador de recursos para que el historial cuente una sola historia.
    final securityTelemetry = SecurityTelemetry();

    final apiClient = ApiClient(
      config: config,
      authSessionTransport: authSessionTransport,
      tokenStore: tokenStore,
      deviceIdentity: deviceIdentity,
      telemetry: securityTelemetry,
    );

    final storyAssetLoader = StoryAssetLoader(apiClient, telemetry: securityTelemetry);
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSource(apiClient),
      authSessionTransport: authSessionTransport,
      tokenStore: tokenStore,
      sessionRestorer: apiClient,
      // Cachés privadas que deben vaciarse en cada cambio de sesión.
      sessionCaches: [storyAssetLoader, securityTelemetry],
      preferences: preferences,
      deviceIdentity: deviceIdentity,
    );
    final storiesRepository = StoriesRepositoryImpl(
      remoteDataSource: StoriesRemoteDataSource(apiClient),
    );
    final readerRepository = ReaderRepositoryImpl(
      remoteDataSource: ReaderRemoteDataSource(apiClient),
    );
    final vocabularyRepository = VocabularyRepositoryImpl(
      remoteDataSource: VocabularyRemoteDataSource(apiClient),
    );

    return AppDependencies(
      config: config,
      secureStorage: secureStorage,
      preferences: preferences,
      deviceIdentity: deviceIdentity,
      apiClient: apiClient,
      storyAssetLoader: storyAssetLoader,
      authRepository: authRepository,
      storiesRepository: storiesRepository,
      readerRepository: readerRepository,
      vocabularyRepository: vocabularyRepository,
    );
  }
}
