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
  int downloads = 0;

  @override
  Future<Uint8List> getBytes(String path) async {
    downloads += 1;
    return Uint8List.fromList(const [1, 2, 3]);
  }

  // El resto del contrato de ApiClient no participa en esta prueba.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
