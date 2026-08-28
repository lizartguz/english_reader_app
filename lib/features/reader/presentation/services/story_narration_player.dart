import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Contrato de reproducción de narración para poder probar la UI sin plugins.
abstract class StoryNarrationPlayer {
  /// Emite la posición reproducida para mover la barra de avance.
  Stream<Duration> get onPositionChanged;

  /// Emite la duración total cuando el audio queda listo.
  Stream<Duration> get onDurationChanged;

  /// Emite si la narración está sonando o en pausa.
  Stream<bool> get onPlayingChanged;

  Future<void> load(Uint8List bytes, {String? mimeType});

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> dispose();
}

/// Reproduce la narración descargada desde la API en móvil y Web.
class PluginStoryNarrationPlayer implements StoryNarrationPlayer {
  PluginStoryNarrationPlayer({AudioPlayer? audioPlayer})
    : _player = audioPlayer ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;

  @override
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;

  @override
  Stream<bool> get onPlayingChanged =>
      _player.onPlayerStateChanged.map((state) => state == PlayerState.playing);

  /// Carga los bytes autenticados porque la URL del recurso exige sesión.
  @override
  Future<void> load(Uint8List bytes, {String? mimeType}) {
    return _player.setSource(BytesSource(bytes, mimeType: mimeType));
  }

  @override
  Future<void> play() => _player.resume();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> dispose() => _player.dispose();
}
