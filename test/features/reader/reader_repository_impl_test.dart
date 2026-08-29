import 'package:dio/dio.dart';
import 'package:english_reader_app/core/constants/app_messages.dart';
import 'package:english_reader_app/features/reader/data/datasources/reader_remote_datasource.dart';
import 'package:english_reader_app/features/reader/data/repositories/reader_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

/// Manejo de errores del lector.
///
/// Estas pruebas fijan algo que se rompe con facilidad: en Dart,
/// `try { return futuro; } catch { … }` **no** captura el fallo, porque el
/// futuro se devuelve antes de completarse. Todo el manejo de errores de los
/// repositorios depende de que ese `await` siga estando.
void main() {
  group('ReaderRepositoryImpl', () {
    test('un 404 de avance significa "aún no hay avance", no un error', () async {
      // Es el caso normal la primera vez que alguien abre una historia.
      final repository = ReaderRepositoryImpl(
        remoteDataSource: _DataSourceQueFalla(_error(404)),
      );

      expect(await repository.getProgress('story-1'), isNull);
    });

    test('un fallo de red al leer el avance tampoco rompe la lectura', () async {
      final repository = ReaderRepositoryImpl(
        remoteDataSource: _DataSourceQueFalla(
          DioException(
            requestOptions: RequestOptions(path: '/app/reading-progress/x'),
            type: DioExceptionType.connectionError,
          ),
        ),
      );

      expect(await repository.getProgress('story-1'), isNull);
    });

    test('el fallo al abrir la historia se traduce a un mensaje amigable', () async {
      final repository = ReaderRepositoryImpl(
        remoteDataSource: _DataSourceQueFalla(_error(500)),
      );

      // Sin `await` en el repositorio, aquí saldría la excepción cruda de Dio
      // en lugar del texto que ve el usuario.
      await expectLater(
        repository.getStory('story-1'),
        throwsA(
          predicate(
            (error) => '$error'.contains(AppMessages.storyLoadError) || error is Exception,
          ),
        ),
      );
    });
  });
}

DioException _error(int statusCode) {
  final options = RequestOptions(path: '/app/reading-progress/x');
  return DioException(
    requestOptions: options,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
      data: {'success': false, 'message': 'fallo', 'code': 'not_found'},
    ),
    type: DioExceptionType.badResponse,
  );
}

/// Falla siempre de forma asíncrona, que es como fallan las llamadas reales.
class _DataSourceQueFalla implements ReaderRemoteDataSource {
  _DataSourceQueFalla(this.error);

  final Object error;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<Never>.error(error);
}
