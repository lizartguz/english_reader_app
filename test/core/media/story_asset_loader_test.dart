import 'dart:typed_data';

import 'package:english_reader_app/core/media/story_asset_loader.dart';
import 'package:english_reader_app/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoryAssetLoader', () {
    test('reutiliza el recurso ya descargado', () async {
      final api = _FakeApiClient();
      final loader = StoryAssetLoader(api);

      await loader.load('asset-1');
      await loader.load('asset-1');

      expect(api.downloads, 1);
    });

    test('descarta lo mas antiguo al pasar del tope de recursos', () async {
      final api = _FakeApiClient();
      final loader = StoryAssetLoader(api, maxEntries: 2);

      await loader.load('a');
      await loader.load('b');
      await loader.load('c'); // desaloja 'a', el menos usado recientemente

      expect(loader.entryCount, 2);
      await loader.load('a');
      expect(api.downloads, 4, reason: 'a se habia descartado y hay que volver a pedirlo');
      await loader.load('c');
      expect(api.downloads, 4, reason: 'c seguia en cache');
    });

    test('consultar un recurso lo protege del desalojo', () async {
      final api = _FakeApiClient();
      final loader = StoryAssetLoader(api, maxEntries: 2);

      await loader.load('a');
      await loader.load('b');
      await loader.load('a'); // 'a' vuelve a ser el mas reciente
      await loader.load('c'); // ahora el que sobra es 'b'

      await loader.load('a');
      expect(api.downloads, 3, reason: 'a seguia en cache por haberse usado');
    });

    test('descarta lo mas antiguo al pasar del tope de memoria', () async {
      final api = _FakeApiClient(bytesPorRecurso: 400);
      final loader = StoryAssetLoader(api, maxBytes: 1000, maxEntries: 100);

      await loader.load('a');
      await loader.load('b');
      expect(loader.usedBytes, 800);

      await loader.load('c'); // 1200 bytes no caben: sale 'a'
      expect(loader.usedBytes, 800);
      expect(loader.entryCount, 2);
    });

    test('un recurso mas grande que el tope no desaloja a los demas', () async {
      final api = _FakeApiClient(bytesPorRecurso: 5000);
      final loader = StoryAssetLoader(api, maxBytes: 1000);

      final bytes = await loader.load('enorme');

      // Se entrega igual, pero guardarlo vaciaria la cache sin llegar a caber.
      expect(bytes.length, 5000);
      expect(loader.entryCount, 0);
      expect(loader.usedBytes, 0);
    });

    test('vaciar la cache tambien pone la memoria en cero', () async {
      final api = _FakeApiClient(bytesPorRecurso: 100);
      final loader = StoryAssetLoader(api);

      await loader.load('a');
      expect(loader.usedBytes, 100);

      loader.clear();
      expect(loader.usedBytes, 0);
      expect(loader.entryCount, 0);
    });

    test('tras vaciar la cache vuelve a pedir el recurso a la API', () async {
      final api = _FakeApiClient();
      final loader = StoryAssetLoader(api);

      await loader.load('asset-1');
      loader.clear();
      await loader.load('asset-1');

      // Si siguiera sirviendo la copia en memoria, el usuario que inicie sesión
      // después vería un recurso privado de la sesión anterior.
      expect(api.downloads, 2);
    });
  });
}

class _FakeApiClient implements ApiClient {
  _FakeApiClient({this.bytesPorRecurso = 3});

  final int bytesPorRecurso;
  int downloads = 0;

  @override
  Future<Uint8List> getBytes(String path) async {
    downloads += 1;
    return Uint8List(bytesPorRecurso);
  }

  // El resto del contrato de ApiClient no participa en esta prueba.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
