import 'package:english_reader_app/core/security/browser_url_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('removeSensitiveQueryParameterFromUrl', () {
    test('quita el token y conserva otros parametros en URL normal', () {
      final url = removeSensitiveQueryParameterFromUrl(
        'https://app.readeriz.com/reset-password?token=abc123&src=email',
        parameterName: 'token',
      );

      expect(url, 'https://app.readeriz.com/reset-password?src=email');
    });

    test('quita el token aunque sea el unico parametro', () {
      final url = removeSensitiveQueryParameterFromUrl(
        'https://app.readeriz.com/reset-password?token=abc123',
        parameterName: 'token',
      );

      expect(url, 'https://app.readeriz.com/reset-password');
    });

    test('quita el token dentro de rutas hash de Flutter Web', () {
      final url = removeSensitiveQueryParameterFromUrl(
        'https://app.readeriz.com/#/reset-password?token=abc123&src=email',
        parameterName: 'token',
      );

      expect(url, 'https://app.readeriz.com/#/reset-password?src=email');
    });

    test('lee el token dentro de rutas hash de Flutter Web', () {
      final token = readSensitiveQueryParameterFromUrl(
        'https://app.readeriz.com/#/reset-password?token=abc123&src=email',
        parameterName: 'token',
      );

      expect(token, 'abc123');
    });

    test('no modifica URLs que no contienen el parametro sensible', () {
      const original = 'https://app.readeriz.com/reset-password?src=email';

      final url = removeSensitiveQueryParameterFromUrl(
        original,
        parameterName: 'token',
      );

      expect(url, original);
    });
  });
}
