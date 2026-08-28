import 'package:flutter/foundation.dart';

/// Configuración de ambiente inyectada por `--dart-define`.
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.environment,
    required this.appVersion,
    required this.csrfCookieName,
  });

  /// Lee la configuración real de compilación y aplica las reglas de seguridad.
  factory AppConfig.fromEnvironment() {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    const configuredEnvironment = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    const configuredAppVersion = String.fromEnvironment(
      'APP_VERSION',
      defaultValue: '0.1.0',
    );
    const configuredCsrfCookieName = String.fromEnvironment(
      'CSRF_COOKIE_NAME',
      defaultValue: 'er_csrf_token',
    );

    return AppConfig.resolve(
      apiBaseUrl: configuredBaseUrl,
      environment: configuredEnvironment,
      appVersion: configuredAppVersion,
      csrfCookieName: configuredCsrfCookieName,
      isWeb: kIsWeb,
      targetPlatform: defaultTargetPlatform,
    );
  }

  final String apiBaseUrl;
  final String environment;
  final String appVersion;
  final String csrfCookieName;

  /// Resuelve la configuración permitiendo probar reglas sin depender del build.
  @visibleForTesting
  factory AppConfig.resolve({
    String apiBaseUrl = '',
    String environment = 'development',
    String appVersion = '0.1.0',
    String csrfCookieName = 'er_csrf_token',
    bool isWeb = false,
    TargetPlatform targetPlatform = TargetPlatform.android,
  }) {
    final normalizedEnvironment = environment.trim().toLowerCase();
    final configuredBaseUrl = apiBaseUrl.trim();
    final resolvedBaseUrl = configuredBaseUrl.isEmpty
        ? _defaultApiBaseUrl(isWeb: isWeb, targetPlatform: targetPlatform)
        : configuredBaseUrl;

    _validateEnvironmentConfig(
      configuredBaseUrl: configuredBaseUrl,
      resolvedBaseUrl: resolvedBaseUrl,
      environment: normalizedEnvironment,
    );

    return AppConfig(
      apiBaseUrl: resolvedBaseUrl,
      environment: normalizedEnvironment,
      appVersion: appVersion,
      csrfCookieName: csrfCookieName.trim().isEmpty
          ? 'er_csrf_token'
          : csrfCookieName.trim(),
    );
  }

  /// Define defaults locales solo para desarrollo.
  static String _defaultApiBaseUrl({
    required bool isWeb,
    required TargetPlatform targetPlatform,
  }) {
    if (isWeb) return 'http://localhost:3000/api/v1';
    return targetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000/api/v1'
        : 'http://localhost:3000/api/v1';
  }

  /// Evita que ambientes protegidos usen URLs locales o sin HTTPS.
  static void _validateEnvironmentConfig({
    required String configuredBaseUrl,
    required String resolvedBaseUrl,
    required String environment,
  }) {
    const allowedEnvironments = {'development', 'staging', 'production'};
    if (!allowedEnvironments.contains(environment)) {
      throw StateError('APP_ENV debe ser development, staging o production.');
    }

    final uri = Uri.tryParse(resolvedBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('API_BASE_URL debe ser una URL absoluta válida.');
    }

    if (environment == 'development') return;

    if (configuredBaseUrl.isEmpty) {
      throw StateError('API_BASE_URL es obligatorio para $environment.');
    }

    if (uri.scheme.toLowerCase() != 'https') {
      throw StateError('API_BASE_URL debe usar HTTPS para $environment.');
    }

    if (_isLocalHost(uri.host)) {
      throw StateError(
        'API_BASE_URL no puede apuntar a localhost en $environment.',
      );
    }
  }

  /// Identifica hosts reservados para desarrollo local.
  static bool _isLocalHost(String host) {
    final normalizedHost = host.toLowerCase();
    return normalizedHost == 'localhost' ||
        normalizedHost == '127.0.0.1' ||
        normalizedHost == '0.0.0.0' ||
        normalizedHost == '::1' ||
        normalizedHost == '10.0.2.2';
  }
}
