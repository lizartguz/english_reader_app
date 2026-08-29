import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:english_reader_app/core/network/api_client.dart';
import 'package:english_reader_app/features/reader/domain/entities/word_detail.dart';
import 'package:english_reader_app/features/reader/presentation/services/word_pronunciation_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// El audio de pronunciación se pide a la API, no al proveedor externo
/// (hallazgo FLT-SEC-009).
void main() {
  group('PluginWordPronunciationPlayer', () {
    test('descarga el audio desde la API y lo reproduce como bytes', () async {
      final api = _FakeApiClient(bytes: Uint8List.fromList(const [1, 2, 3]));
      final audio = _FakeAudioPlayer();
      final player = PluginWordPronunciationPlayer(
        apiClient: api,
        audioPlayer: audio,
        tts: _FakeTts(),
      );

      final resultado = await player.play(_palabra(pronunciacionId: 'pron-9'));

      expect(resultado.source, PronunciationPlaybackSource.remoteAudio);
      expect(api.rutas, ['/app/words/pronunciations/pron-9/audio']);
      // Reproducir por URL haría que el dispositivo del lector contactara al
      // proveedor externo, que es justo lo que este cambio evita.
      expect(audio.fuentes.single, isA<BytesSource>());
    });

    test('codifica el identificador en la ruta', () async {
      final api = _FakeApiClient(bytes: Uint8List.fromList(const [1]));
      final player = PluginWordPronunciationPlayer(
        apiClient: api,
        audioPlayer: _FakeAudioPlayer(),
        tts: _FakeTts(),
      );

      await player.play(_palabra(pronunciacionId: 'pron/../otro'));

      expect(api.rutas.single, contains('pron%2F..%2Fotro'));
    });

    test('recurre a la voz local cuando la API no entrega audio', () async {
      final api = _FakeApiClient(error: StateError('sin audio'));
      final tts = _FakeTts();
      final player = PluginWordPronunciationPlayer(
        apiClient: api,
        audioPlayer: _FakeAudioPlayer(),
        tts: tts,
      );

      final resultado = await player.play(_palabra(pronunciacionId: 'pron-9'));

      expect(resultado.source, PronunciationPlaybackSource.localTts);
      expect(tts.dichas, ['hello']);
    });

    test('usa la voz local si la palabra no tiene ninguna pronunciación con audio', () async {
      final api = _FakeApiClient(bytes: Uint8List.fromList(const [1]));
      final tts = _FakeTts();
      final player = PluginWordPronunciationPlayer(
        apiClient: api,
        audioPlayer: _FakeAudioPlayer(),
        tts: tts,
      );

      final resultado = await player.play(_palabra(pronunciacionId: null));

      expect(resultado.source, PronunciationPlaybackSource.localTts);
      expect(api.rutas, isEmpty);
    });
  });
}

WordDetail _palabra({required String? pronunciacionId}) {
  return WordDetail(
    id: 'word-1',
    word: 'hello',
    normalizedWord: 'hello',
    language: 'en',
    translations: const [],
    examples: const [],
    pronunciations: [
      if (pronunciacionId != null)
        WordPronunciation(
          id: pronunciacionId,
          audioUrl: 'https://proveedor.example/hello.mp3',
        )
      else
        const WordPronunciation(id: 'sin-audio'),
    ],
    isSaved: false,
  );
}

class _FakeApiClient implements ApiClient {
  _FakeApiClient({this.bytes, this.error});

  final Uint8List? bytes;
  final Object? error;
  final rutas = <String>[];

  @override
  Future<Uint8List> getBytes(String path) async {
    rutas.add(path);
    if (error != null) throw error!;
    return bytes!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAudioPlayer implements AudioPlayer {
  final fuentes = <Source>[];

  @override
  Future<void> play(Source source, {double? volume, double? balance, AudioContext? ctx, Duration? position, PlayerMode? mode}) async {
    fuentes.add(source);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTts implements FlutterTts {
  final dichas = <String>[];

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    dichas.add(text);
    return 1;
  }

  @override
  Future<dynamic> setLanguage(String language) async => 1;

  @override
  Future<dynamic> stop() async => 1;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
