import 'dart:typed_data';

import 'package:english_reader_app/core/constants/app_routes.dart';
import 'package:english_reader_app/core/media/story_asset_loader.dart';
import 'package:english_reader_app/core/network/api_client.dart';
import 'package:english_reader_app/features/reader/data/datasources/reader_remote_datasource.dart';
import 'package:english_reader_app/features/stories/data/datasources/stories_remote_datasource.dart';
import 'package:english_reader_app/features/vocabulary/data/datasources/vocabulary_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los identificadores que viajan como segmento de URL se codifican
/// (hallazgo FLT-SEC-010).
///
/// Se usa un identificador hostil y se comprueba la ruta que realmente sale
/// hacia la API. Lo que se verifica no es que aparezcan caracteres concretos
/// escapados, sino la propiedad que importa: **el identificador no puede salir
/// de su segmento**. Los puntos no se codifican —ni hace falta—, pero una barra
/// o un `?` sin escapar sí apuntarían a otro recurso.
void main() {
  const idHostil = '../../admin/users?x=1';

  test('el detalle de historia mantiene el id dentro de su segmento', () async {
    final api = _ApiEspia();
    await _ignorarCorte(() => ReaderRemoteDataSource(api).getStory(idHostil));

    _esperarSegmentoAislado(api.ultimaRuta, '/app/stories/');
  });

  test('el avance de lectura mantiene el id dentro de su segmento', () async {
    final api = _ApiEspia();
    await _ignorarCorte(() => ReaderRemoteDataSource(api).getProgress(idHostil));

    _esperarSegmentoAislado(api.ultimaRuta, '/app/reading-progress/');
  });

  test('el listado de historias mantiene el id dentro de su segmento', () async {
    final api = _ApiEspia();
    await _ignorarCorte(() => StoriesRemoteDataSource(api).getStory(idHostil));

    _esperarSegmentoAislado(api.ultimaRuta, '/app/stories/');
  });

  test('vocabulario mantiene el id dentro de su segmento al borrar', () async {
    final api = _ApiEspia();
    await _ignorarCorte(() => VocabularyRemoteDataSource(api).deleteVocabulary(idHostil));

    _esperarSegmentoAislado(api.ultimaRuta, '/app/vocabulary/');
  });

  test('la descarga de recursos privados mantiene el id en su segmento', () async {
    final api = _ApiEspia();
    await _ignorarCorte(() => StoryAssetLoader(api).load(idHostil));

    _esperarSegmentoAislado(api.ultimaRuta, '/files/story-assets/');
  });

  test('la ruta interna del lector mantiene el id dentro de su segmento', () {
    // `go_router` no encontraría `/reader/:storyId` si el id trajera barras.
    _esperarSegmentoAislado(AppRoutes.readerPath(idHostil), '/reader/');
    expect(AppRoutes.readerPath('abc'), '/reader/abc');
  });
}

/// Comprueba que lo que sigue al prefijo sea un único segmento de ruta.
void _esperarSegmentoAislado(String? ruta, String prefijo) {
  expect(ruta, isNotNull);
  expect(ruta, startsWith(prefijo));

  final segmento = ruta!.substring(prefijo.length);
  expect(segmento, isNot(contains('/')), reason: 'el id abriría una ruta nueva');
  expect(segmento, isNot(contains('?')), reason: 'el id abriría una query');
  expect(segmento, isNotEmpty);
}

/// Ejecuta la llamada y descarta el corte: aquí solo interesa la ruta pedida.
Future<void> _ignorarCorte(Future<Object?> Function() accion) async {
  try {
    await accion();
  } catch (_) {
    // El espía corta siempre; la ruta ya quedó registrada.
  }
}

/// Registra la ruta pedida y corta la llamada: aquí solo interesa la URL.
class _ApiEspia implements ApiClient {
  String? ultimaRuta;

  @override
  Future<ApiPayload<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    ultimaRuta = path;
    throw _Corte();
  }

  @override
  Future<ApiPayload<T>> patch<T>(String path, {Object? data}) {
    ultimaRuta = path;
    throw _Corte();
  }

  @override
  Future<ApiPayload<T>> delete<T>(String path) {
    ultimaRuta = path;
    throw _Corte();
  }

  @override
  Future<Uint8List> getBytes(String path) {
    ultimaRuta = path;
    throw _Corte();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Corte implements Exception {}
