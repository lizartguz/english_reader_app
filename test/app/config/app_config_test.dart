import 'package:english_reader_app/app/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('usa URL local por defecto en desarrollo Android', () {
      final config = AppConfig.resolve(targetPlatform: TargetPlatform.android);

      expect(config.environment, 'development');
      expect(config.apiBaseUrl, 'http://10.0.2.2:3000/api/v1');
    });

    test('usa URL local por defecto en desarrollo Web', () {
      final config = AppConfig.resolve(
        isWeb: true,
        targetPlatform: TargetPlatform.windows,
      );

      expect(config.apiBaseUrl, 'http://localhost:3000/api/v1');
    });

    test('exige API_BASE_URL explícita en producción', () {
      expect(
        () => AppConfig.resolve(environment: 'production'),
        throwsA(isA<StateError>()),
      );
    });

    test('rechaza HTTP en ambientes protegidos', () {
      expect(
        () => AppConfig.resolve(
          apiBaseUrl: 'http://api.readeriz.com/api/v1',
          environment: 'staging',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rechaza localhost en ambientes protegidos', () {
      expect(
        () => AppConfig.resolve(
          apiBaseUrl: 'https://localhost:3000/api/v1',
          environment: 'production',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('acepta HTTPS explícito en producción', () {
      final config = AppConfig.resolve(
        apiBaseUrl: 'https://api.readeriz.com/api/v1',
        environment: 'production',
        appVersion: '1.2.3',
        csrfCookieName: 'readeriz_csrf',
      );

      expect(config.apiBaseUrl, 'https://api.readeriz.com/api/v1');
      expect(config.environment, 'production');
      expect(config.appVersion, '1.2.3');
      expect(config.csrfCookieName, 'readeriz_csrf');
    });
  });
}
