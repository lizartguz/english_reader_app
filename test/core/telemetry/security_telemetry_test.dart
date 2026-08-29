import 'package:english_reader_app/core/telemetry/security_event.dart';
import 'package:english_reader_app/core/telemetry/security_telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registro saneado de incidencias de seguridad (hallazgo FLT-SEC-017).
void main() {
  group('sanitizeEndpoint', () {
    test('sustituye los identificadores de la ruta', () {
      // Registrar la ruta tal cual diria que historia leyo esta persona.
      expect(
        sanitizeEndpoint('/app/stories/01a04b6f-ae19-7469-892f-79a1f8b8bdf9'),
        '/app/stories/{id}',
      );
      expect(
        sanitizeEndpoint('/files/story-assets/01a04067-896a-74b9-8c37-9931c36c1e0d'),
        '/files/story-assets/{id}',
      );
    });

    test('conserva los segmentos que describen el endpoint', () {
      expect(sanitizeEndpoint('/auth/refresh'), '/auth/refresh');
      expect(sanitizeEndpoint('/app/words/lookup'), '/app/words/lookup');
      expect(
        sanitizeEndpoint('/app/words/pronunciations/01a04067-896a-74b9/audio'),
        '/app/words/pronunciations/{id}/audio',
      );
    });

    test('descarta la query, que puede llevar lo que busco el usuario', () {
      expect(sanitizeEndpoint('/app/words/lookup?word=umbrella'), '/app/words/lookup');
    });
  });

  group('SecurityTelemetry', () {
    test('sanea la ruta aunque quien registra pase el identificador', () async {
      final telemetry = SecurityTelemetry();

      telemetry.record(
        SecurityEventType.sessionExpired,
        endpoint: '/app/stories/01a04b6f-ae19-7469-892f-79a1f8b8bdf9',
        statusCode: 401,
        errorCode: 'token_expired',
      );

      // El saneado vive en el canal, no en quien llama: asi no se puede colar
      // una ruta sin sanear por olvido.
      expect(telemetry.history.single.endpoint, '/app/stories/{id}');
      await telemetry.dispose();
    });

    test('el evento no puede llevar tokens, correos ni contrasenas', () async {
      final telemetry = SecurityTelemetry();

      telemetry.record(
        SecurityEventType.loginRejected,
        endpoint: '/auth/login',
        statusCode: 401,
        errorCode: 'invalid_credentials',
      );

      // El evento solo expone estos campos: no hay donde meter un secreto.
      final evento = telemetry.history.single;
      final texto = evento.toString();
      for (final secreto in const [
        'lector@test.local',
        'Clave123*',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9',
      ]) {
        expect(texto, isNot(contains(secreto)));
      }
      expect(evento.errorCode, 'invalid_credentials');
      await telemetry.dispose();
    });

    test('el historial no crece sin limite', () async {
      final telemetry = SecurityTelemetry(maxHistory: 3);

      for (var i = 0; i < 10; i++) {
        telemetry.record(SecurityEventType.apiUnavailable, endpoint: '/app/stories');
      }

      expect(telemetry.history.length, 3);
      await telemetry.dispose();
    });

    test('publica los eventos segun ocurren', () async {
      final telemetry = SecurityTelemetry();
      final recibidos = <SecurityEventType>[];
      final suscripcion = telemetry.events.listen((e) => recibidos.add(e.type));

      telemetry.record(SecurityEventType.refreshFailed);
      telemetry.record(SecurityEventType.rateLimited);
      await Future<void>.delayed(Duration.zero);

      expect(recibidos, [
        SecurityEventType.refreshFailed,
        SecurityEventType.rateLimited,
      ]);
      await suscripcion.cancel();
      await telemetry.dispose();
    });

    test('cerrar sesion descarta el historial de la sesion anterior', () async {
      final telemetry = SecurityTelemetry();
      telemetry.record(SecurityEventType.sessionExpired);
      expect(telemetry.history, hasLength(1));

      telemetry.clear();

      expect(telemetry.history, isEmpty);
      await telemetry.dispose();
    });
  });
}
