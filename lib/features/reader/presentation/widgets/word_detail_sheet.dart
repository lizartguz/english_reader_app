import 'package:flutter/material.dart';

import '../../../../core/accessibility/app_semantics.dart';
import '../../../../core/constants/app_keys.dart';
import '../../domain/entities/word_detail.dart';
import '../services/word_pronunciation_player.dart';

/// Modal de detalle que muestra significado, ejemplos y pronunciación.
class WordDetailSheet extends StatefulWidget {
  const WordDetailSheet({
    required this.word,
    required this.isSaving,
    required this.onSave,
    this.pronunciationPlayer,
    super.key,
  });

  final WordDetail word;
  final bool isSaving;
  final VoidCallback onSave;
  final WordPronunciationPlayer? pronunciationPlayer;

  @override
  State<WordDetailSheet> createState() => _WordDetailSheetState();
}

class _WordDetailSheetState extends State<WordDetailSheet> {
  late final WordPronunciationPlayer _pronunciationPlayer;
  bool _isPronouncing = false;
  String? _pronunciationMessage;

  @override
  void initState() {
    super.initState();
    _pronunciationPlayer =
        widget.pronunciationPlayer ?? PluginWordPronunciationPlayer();
  }

  @override
  void dispose() {
    _pronunciationPlayer.dispose();
    super.dispose();
  }

  /// Construye el detalle de palabra con acciones seguras para móvil y Web.
  @override
  Widget build(BuildContext context) {
    final word = widget.word;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      word.word,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: _isPronouncing
                        ? AppSemantics.pronouncingWord(word.word)
                        : AppSemantics.pronounceWord(word.word),
                    child: IconButton(
                      key: AppKeys.wordPronunciationButton,
                      tooltip: 'Pronunciar',
                      onPressed: _isPronouncing ? null : _speak,
                      icon: _isPronouncing
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.volume_up_outlined),
                    ),
                  ),
                ],
              ),
              if (word.phonetic != null || word.partOfSpeech != null)
                Text(
                  [
                    if (word.phonetic != null) word.phonetic,
                    if (word.partOfSpeech != null) word.partOfSpeech,
                  ].join(' · '),
                ),
              if (_pronunciationMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _pronunciationMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _Section(
                title: 'Traducción',
                child: Text(
                  word.primaryTranslation ?? 'Sin traducción disponible.',
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Definición',
                child: Text(word.definitionEn ?? 'Sin definición disponible.'),
              ),
              if (word.examples.isNotEmpty) ...[
                const SizedBox(height: 16),
                _Section(
                  title: 'Ejemplos',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: word.examples
                        .map(
                          (example) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('• ${example.exampleText}'),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: word.isSaved || widget.isSaving
                    ? null
                    : widget.onSave,
                icon: widget.isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        word.isSaved
                            ? Icons.bookmark_added
                            : Icons.bookmark_add_outlined,
                      ),
                label: Text(word.isSaved ? 'Guardada' : 'Guardar palabra'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reproduce pronunciación remota y muestra fallback TTS cuando aplica.
  Future<void> _speak() async {
    setState(() {
      _isPronouncing = true;
      _pronunciationMessage = null;
    });

    try {
      final result = await _pronunciationPlayer.play(widget.word);
      if (!mounted) return;
      setState(() {
        _pronunciationMessage =
            result.source == PronunciationPlaybackSource.remoteAudio
            ? 'Reproduciendo audio de la palabra.'
            : 'Usando voz del dispositivo.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pronunciationMessage = 'No se pudo reproducir la pronunciación.';
      });
    } finally {
      if (mounted) {
        setState(() => _isPronouncing = false);
      }
    }
  }
}

/// Sección reusable para bloques de información de la palabra.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  /// Renderiza título y contenido con espaciado consistente.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
