import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/accessibility/app_semantics.dart';
import '../../../../core/constants/app_keys.dart';
import '../../../stories/domain/entities/story.dart';
import '../services/story_narration_player.dart';

/// Controles para escuchar la narración publicada junto a la historia.
class StoryNarrationBar extends StatefulWidget {
  const StoryNarrationBar({
    required this.asset,
    required this.loadAudio,
    this.player,
    super.key,
  });

  final StoryAsset asset;
  final Future<Uint8List> Function(String assetId) loadAudio;
  final StoryNarrationPlayer? player;

  @override
  State<StoryNarrationBar> createState() => _StoryNarrationBarState();
}

class _StoryNarrationBarState extends State<StoryNarrationBar> {
  late final StoryNarrationPlayer _player;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = widget.player ?? PluginStoryNarrationPlayer();
    _listenPlayer();
    _loadAudio();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  /// Muestra carga, error recuperable o los controles de reproducción.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: switch ((_isLoading, _error)) {
          (true, _) => const _NarrationMessage(
            message: 'Preparando la narración...',
            showProgress: true,
          ),
          (_, final String message) => Row(
            children: [
              Expanded(child: _NarrationMessage(message: message)),
              TextButton(
                onPressed: _loadAudio,
                child: const Text('Reintentar'),
              ),
            ],
          ),
          _ => Row(
            children: [
              IconButton(
                key: AppKeys.readerNarrationButton,
                tooltip: _isPlaying
                    ? 'Pausar narración'
                    : 'Reproducir narración',
                onPressed: _togglePlayback,
                icon: Icon(
                  _isPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 34,
                ),
              ),
              Expanded(
                child: Semantics(
                  label: AppSemantics.narrationProgress(_position, _duration),
                  child: Slider(
                    value: _sliderValue,
                    onChanged: _duration == Duration.zero ? null : _seekToValue,
                  ),
                ),
              ),
              Text(
                '${_format(_position)} / ${_format(_duration)}',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        },
      ),
    );
  }

  /// Mantiene sincronizada la UI con el estado real del reproductor.
  void _listenPlayer() {
    _subscriptions.addAll([
      _player.onPositionChanged.listen((position) {
        if (mounted) setState(() => _position = position);
      }),
      _player.onDurationChanged.listen((duration) {
        if (mounted) setState(() => _duration = duration);
      }),
      _player.onPlayingChanged.listen((isPlaying) {
        if (mounted) setState(() => _isPlaying = isPlaying);
      }),
    ]);
  }

  /// Descarga la narración con la sesión activa porque el recurso es privado.
  Future<void> _loadAudio() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bytes = await widget.loadAudio(widget.asset.id);
      await _player.load(bytes, mimeType: widget.asset.mimeType);
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'No se pudo cargar la narración.';
      });
    }
  }

  /// Alterna reproducción y pausa sin perder la posición actual.
  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
    if (mounted) setState(() => _isPlaying = !_isPlaying);
  }

  /// Convierte el valor del deslizador en una posición real del audio.
  Future<void> _seekToValue(double value) async {
    final target = Duration(
      milliseconds: (_duration.inMilliseconds * value).round(),
    );
    setState(() => _position = target);
    await _player.seek(target);
  }

  double get _sliderValue {
    if (_duration.inMilliseconds <= 0) return 0;
    final value = _position.inMilliseconds / _duration.inMilliseconds;
    return value.clamp(0, 1).toDouble();
  }

  /// Formatea la duración en minutos y segundos legibles.
  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Mensaje compacto usado durante carga o error de la narración.
class _NarrationMessage extends StatelessWidget {
  const _NarrationMessage({required this.message, this.showProgress = false});

  final String message;
  final bool showProgress;

  /// Mantiene la altura estable para que el lector no salte al cargar.
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showProgress) ...[
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
        ] else ...[
          Icon(
            Icons.headset_off_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(child: Text(message)),
      ],
    );
  }
}
