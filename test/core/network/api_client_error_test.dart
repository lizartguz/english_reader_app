import 'package:dio/dio.dart';
import 'package:english_reader_app/core/constants/app_messages.dart';
import 'package:english_reader_app/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapDioException', () {
    test('convierte fallos de conexion en mensaje amigable', () {
      final exception = mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/app/stories'),
          type: DioExceptionType.connectionError,
        ),
        AppMessages.storiesLoadError,
      );

      expect(exception.message, AppMessages.apiUnavailable);
    });

    test(
      'usa mensaje de sesion para 401 aunque el backend envie otro texto',
      () {
        final exception = mapDioException(
          _responseError(
            statusCode: 401,
            data: {
              'success': false,
              'message': 'Texto variable de API',
              'code': 'token_expired',
            },
          ),
          AppMessages.genericError,
        );

        expect(exception.message, AppMessages.sessionExpired);
        expect(exception.code, 'token_expired');
        expect(exception.statusCode, 401);
      },
    );

    test('usa mensaje de permisos para 403', () {
      final exception = mapDioException(
        _responseError(
          statusCode: 403,
          data: {
            'success': false,
            'message': 'No autorizado para este recurso',
            'code': 'forbidden',
          },
        ),
        AppMessages.genericError,
      );

      expect(exception.message, AppMessages.forbidden);
    });

    test('mantiene mensaje controlado para recursos no encontrados', () {
      final exception = mapDioException(
        _responseError(
          statusCode: 404,
          data: {
            'success': false,
            'message': 'No se encontro informacion para la palabra solicitada.',
            'code': 'not_found',
          },
        ),
        AppMessages.wordLookupError,
      );

      expect(
        exception.message,
        'No se encontro informacion para la palabra solicitada.',
      );
      expect(exception.isNotFound, isTrue);
    });

    test('normaliza limite de solicitudes', () {
      final exception = mapDioException(
        _responseError(
          statusCode: 429,
          data: {
            'success': false,
            'message': 'Too many requests',
            'code': 'rate_limited',
          },
        ),
        AppMessages.genericError,
      );

      expect(exception.message, AppMessages.rateLimited);
    });

    test('no expone mensajes tecnicos de errores 500', () {
      final exception = mapDioException(
        _responseError(
          statusCode: 500,
          data: {
            'success': false,
            'message': 'SQLSTATE[HY000] detalle interno',
            'code': 'internal_error',
          },
        ),
        AppMessages.storyLoadError,
      );

      expect(exception.message, AppMessages.storyLoadError);
    });
  });
}

/// Construye un `DioException` con respuesta HTTP controlada para pruebas.
DioException _responseError({
  required int statusCode,
  required Map<String, dynamic> data,
}) {
  final requestOptions = RequestOptions(path: '/api-test');
  return DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: data,
    ),
  );
}
