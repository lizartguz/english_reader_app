import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/entities/word_detail.dart';

/// Origen usado para reproducir la pronunciación de una palabra.
enum PronunciationPlaybackSource { remoteAudio, localTts }

/// Resultado mínimo para informar al usuario qué fuente se usó.
class PronunciationPlaybackResult {
  const PronunciationPlaybackResult(this.source);

  final PronunciationPlaybackSource source;
}

/// Contrato de reproducción para poder probar el modal sin plugins reales.
abstract class WordPronunciationPlayer {
  Future<PronunciationPlaybackResult> play(WordDetail word);

  Future<void> dispose();
}

/// Reproduce audio remoto de la API y usa TTS local como respaldo.
class PluginWordPronunciationPlayer implements WordPronunciationPlayer {
  PluginWordPronunciationPlayer({AudioPlayer? audioPlayer, FlutterTts? tts})
    : _audioPlayer = audioPlayer ?? AudioPlayer(),
      _tts = tts ?? FlutterTts();

  final AudioPlayer _audioPlayer;
  final FlutterTts _tts;

  /// Intenta primero la URL remota porque la API es la fuente de contenido.
  @override
  Future<PronunciationPlaybackResult> play(WordDetail word) async {
    await _stopCurrentPlayback();

    final audioUrl = word.preferredAudioUrl;
    if (audioUrl != null) {
      try {
        await _audioPlayer.play(UrlSource(audioUrl));
        return const PronunciationPlaybackResult(
          PronunciationPlaybackSource.remoteAudio,
        );
      } catch (_) {
        // Si la URL temporal expiró o falla la red, se mantiene la experiencia.
      }
    }

    await _tts.setLanguage(_ttsLanguageFor(word.language));
    await _tts.speak(word.word);
    return const PronunciationPlaybackResult(
      PronunciationPlaybackSource.localTts,
    );
  }

  /// Libera recursos nativos de audio cuando se cierra el modal.
  @override
  Future<void> dispose() async {
    await _stopCurrentPlayback();
    await _audioPlayer.dispose();
  }

  /// Detiene cualquier reproducción previa antes de iniciar otra.
  Future<void> _stopCurrentPlayback() async {
    await _audioPlayer.stop();
    await _tts.stop();
  }

  /// Mapea idioma de la API a una voz TTS razonable por defecto.
  String _ttsLanguageFor(String language) {
    return switch (language.toLowerCase()) {
      'en' || 'en-us' => 'en-US',
      'en-gb' => 'en-GB',
      _ => 'en-US',
    };
  }
}
