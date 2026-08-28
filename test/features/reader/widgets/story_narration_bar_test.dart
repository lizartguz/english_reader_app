import 'dart:async';
import 'dart:typed_data';

import 'package:english_reader_app/core/constants/app_keys.dart';
import 'package:english_reader_app/features/reader/presentation/services/story_narration_player.dart';
import 'package:english_reader_app/features/reader/presentation/widgets/story_narration_bar.dart';
import 'package:english_reader_app/features/stories/domain/entities/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Carga la narración y alterna reproducción y pausa', (
    tester,
  ) async {
    final player = _FakeNarrationPlayer();
    await _pumpBar(tester, player: player);

    expect(player.loadedBytes, isNotNull);
    expect(find.byKey(AppKeys.readerNarrationButton), findsOneWidget);
    expect(find.text('00:00 / 02:00'), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.readerNarrationButton));
    await tester.pump();
    expect(player.playCalls, 1);

    await tester.tap(find.byKey(AppKeys.readerNarrationButton));
    await tester.pump();
    expect(player.pauseCalls, 1);
  });

  testWidgets('Ofrece reintentar cuando la descarga falla', (tester) async {
    final player = _FakeNarrationPlayer();
    var attempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryNarrationBar(
            asset: _asset,
            player: player,
            loadAudio: (_) async {
              attempts += 1;
              if (attempts == 1) throw Exception('sin red');
              return Uint8List.fromList([1, 2, 3]);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudo cargar la narración.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.readerNarrationButton), findsOneWidget);
    expect(attempts, 2);
  });
}

/// Monta la barra con un reproductor controlado por el test.
Future<void> _pumpBar(
  WidgetTester tester, {
  required _FakeNarrationPlayer player,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StoryNarrationBar(
          asset: _asset,
          player: player,
          loadAudio: (_) async => Uint8List.fromList([1, 2, 3]),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  player.emitDuration(const Duration(minutes: 2));
  await tester.pumpAndSettle();
}

const _asset = StoryAsset(
  id: 'asset-1',
  type: 'audio',
  mimeType: 'audio/mpeg',
  accessScope: 'private',
  sortOrder: 0,
  downloadUrl: '/api/v1/files/story-assets/asset-1',
);

/// Reproductor falso para verificar la UI sin plugins de audio.
class _FakeNarrationPlayer implements StoryNarrationPlayer {
  final _positions = StreamController<Duration>.broadcast();
  final _durations = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();

  Uint8List? loadedBytes;
  int playCalls = 0;
  int pauseCalls = 0;

  void emitDuration(Duration duration) => _durations.add(duration);

  @override
  Stream<Duration> get onPositionChanged => _positions.stream;

  @override
  Stream<Duration> get onDurationChanged => _durations.stream;

  @override
  Stream<bool> get onPlayingChanged => _playing.stream;

  @override
  Future<void> load(Uint8List bytes, {String? mimeType}) async {
    loadedBytes = bytes;
  }

  @override
  Future<void> play() async {
    playCalls += 1;
  }

  @override
  Future<void> pause() async {
    pauseCalls += 1;
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> dispose() async {
    await _positions.close();
    await _durations.close();
    await _playing.close();
  }
}
