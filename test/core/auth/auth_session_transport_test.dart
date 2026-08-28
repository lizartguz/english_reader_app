import 'package:english_reader_app/core/auth/auth_session_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSessionTransport', () {
    test('usa mobile para plataformas nativas', () {
      const transport = AuthSessionTransport(isWeb: false);

      expect(transport.clientType, 'mobile');
      expect(transport.usesCookieRefresh, isFalse);
    });

    test('usa app_web para Flutter Web', () {
      const transport = AuthSessionTransport(isWeb: true);

      expect(transport.clientType, 'app_web');
      expect(transport.usesCookieRefresh, isTrue);
    });
  });
}
