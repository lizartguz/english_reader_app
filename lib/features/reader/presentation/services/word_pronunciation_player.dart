import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../core/network/api_client.dart';
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

/// Reproduce el audio servido por la API y usa TTS local como respaldo.
class PluginWordPronunciationPlayer implements WordPronunciationPlayer {
  PluginWordPronunciationPlayer({
    required ApiClient apiClient,
    AudioPlayer? audioPlayer,
    FlutterTts? tts,
  }) : _apiClient = apiClient,
       _audioPlayer = audioPlayer ?? AudioPlayer(),
       _tts = tts ?? FlutterTts();

  final ApiClient _apiClient;
  final AudioPlayer _audioPlayer;
  final FlutterTts _tts;

  /// Pide el audio a la API y, si no hay, recurre a la voz local.
  ///
  /// El audio llega como bytes desde nuestro propio dominio en vez de
  /// reproducirse por URL del proveedor externo: el dispositivo no contacta a
  /// terceros y la Content-Security-Policy de la versión Web puede seguir
  /// permitiendo solo el origen propio.
  @override
  Future<PronunciationPlaybackResult> play(WordDetail word) async {
    await _stopCurrentPlayback();

    final pronunciationId = word.preferredAudioPronunciationId;
    if (pronunciationId != null) {
      try {
        // El identificador se codifica aunque venga de la API: un segmento con
        // caracteres reservados podría alterar la ruta.
        final bytes = await _apiClient.getBytes(
          '/app/words/pronunciations/${Uri.encodeComponent(pronunciationId)}/audio',
        );
        await _audioPlayer.play(BytesSource(bytes));
        return const PronunciationPlaybackResult(
          PronunciationPlaybackSource.remoteAudio,
        );
      } catch (_) {
        // Sin audio disponible o sin red, se mantiene la experiencia con TTS.
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
