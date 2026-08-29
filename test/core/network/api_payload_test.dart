import 'package:english_reader_app/core/constants/app_messages.dart';
import 'package:english_reader_app/core/errors/app_exception.dart';
import 'package:english_reader_app/core/network/api_client.dart';
import 'package:english_reader_app/core/network/payload_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiPayload', () {
    test('acepta payload exitoso con data tipada', () {
      final payload = ApiPayload<Map<String, dynamic>>.fromJson({
        'success': true,
        'message': 'ok',
        'data': {'id': 'story-1'},
        'meta': {'page': 1},
      });

      expect(payload.requireData()['id'], 'story-1');
      expect(payload.meta?['page'], 1);
    });

    test('rechaza envoltura que no es mapa JSON', () {
      expect(
        () => ApiPayload<Map<String, dynamic>>.fromJson(['invalid']),
        throwsA(_isInvalidPayload()),
      );
    });

    test('rechaza success ausente o no booleano', () {
      expect(
        () => ApiPayload<Map<String, dynamic>>.fromJson({
          'success': 'true',
          'data': {'id': 'story-1'},
        }),
        throwsA(_isInvalidPayload()),
      );
    });

    test('rechaza data con tipo distinto al esperado', () {
      expect(
        () => ApiPayload<Map<String, dynamic>>.fromJson({
          'success': true,
          'data': ['story-1'],
        }),
        throwsA(_isInvalidPayload()),
      );
    });

    test('rechaza meta con tipo inesperado', () {
      expect(
        () => ApiPayload<Map<String, dynamic>>.fromJson({
          'success': true,
          'data': {'id': 'story-1'},
          'meta': ['bad-meta'],
        }),
        throwsA(_isInvalidPayload()),
      );
    });

    test('normaliza error API con message y code no textuales', () {
      expect(
        () => ApiPayload<Map<String, dynamic>>.fromJson({
          'success': false,
          'message': {'debug': 'detalle'},
          'code': 500,
        }),
        throwsA(
          isA<AppException>()
              .having(
                (error) => error.message,
                'message',
                AppMessages.genericError,
              )
              .having((error) => error.code, 'code', isNull),
        ),
      );
    });

    test('requireData falla si el endpoint no devuelve cuerpo requerido', () {
      const payload = ApiPayload<Map<String, dynamic>>(
        success: true,
        message: 'ok',
        data: null,
      );

      expect(() => payload.requireData(), throwsA(_isInvalidPayload()));
    });
  });

  group('parseApiPayload', () {
    test('convierte errores de cast en AppException controlada', () {
      expect(
        () => parseApiPayload(() {
          final json = <String, dynamic>{'id': 1};
          return json['id'] as String;
        }),
        throwsA(_isInvalidPayload()),
      );
    });
  });
}

/// Verifica el error estable que representa un payload invalido.
Matcher _isInvalidPayload() {
  return isA<AppException>()
      .having((error) => error.message, 'message', AppMessages.genericError)
      .having((error) => error.code, 'code', invalidPayloadCode);
}
