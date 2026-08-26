import 'package:flutter/foundation.dart';

/// Configuracion de ambiente inyectada por `--dart-define`.
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.environment,
    required this.appVersion,
  });

  factory AppConfig.fromEnvironment() {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

    return AppConfig(
      apiBaseUrl: configuredBaseUrl.isEmpty
          ? _defaultApiBaseUrl
          : configuredBaseUrl,
      environment: const String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
      ),
      appVersion: const String.fromEnvironment(
        'APP_VERSION',
        defaultValue: '0.1.0',
      ),
    );
  }

  final String apiBaseUrl;
  final String environment;
  final String appVersion;

  static String get _defaultApiBaseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000/api/v1'
        : 'http://localhost:3000/api/v1';
  }
}
