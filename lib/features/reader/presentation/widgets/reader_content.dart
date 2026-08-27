import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/accessibility/app_semantics.dart';
import '../../../../core/constants/app_keys.dart';

/// Renderiza contenido textual en palabras tocables para consulta.
class ReaderContent extends StatelessWidget {
  const ReaderContent({
    required this.content,
    required this.onWordTap,
    this.fontScale = 1,
    this.lineHeight = 1.45,
    super.key,
  });

  final String content;
  final ValueChanged<String> onWordTap;
  final double fontScale;
  final double lineHeight;

  /// Construye los párrafos separando cada palabra tocable.
  @override
  Widget build(BuildContext context) {
    final paragraphs = content
        .split(RegExp(r'\n\s*\n'))
        .where((paragraph) => paragraph.trim().isNotEmpty)
        .toList();

    return Column(
      key: AppKeys.readerContent,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final paragraph in paragraphs) ...[
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: paragraph
                .split(RegExp(r'\s+'))
                .where((token) => token.isNotEmpty)
                .indexed
                .map(
                  (item) => _WordToken(
                    token: item.$2,
                    index: item.$1,
                    fontScale: fontScale,
                    lineHeight: lineHeight,
                    onWordTap: onWordTap,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

/// Palabra individual que conserva puntuación alrededor del término real.
class _WordToken extends StatelessWidget {
  const _WordToken({
    required this.token,
    required this.index,
    required this.fontScale,
    required this.lineHeight,
    required this.onWordTap,
  });

  final String token;
  final int index;
  final double fontScale;
  final double lineHeight;
  final ValueChanged<String> onWordTap;

  /// Renderiza la palabra real sin perder la puntuación visual.
  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: 21 * fontScale,
      height: lineHeight,
    );
    final match = RegExp(
      r"^([^A-Za-z]*)([A-Za-z]+(?:'[A-Za-z]+)?)([^A-Za-z]*)$",
    ).firstMatch(token);

    if (match == null) {
      return Text(token, style: textStyle);
    }

    final leading = match.group(1) ?? '';
    final word = match.group(2) ?? token;
    final trailing = match.group(3) ?? '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading.isNotEmpty) Text(leading, style: textStyle),
        Semantics(
          button: true,
          label: AppSemantics.readerWord(word),
          onTap: () => onWordTap(word),
          child: ExcludeSemantics(
            child: Shortcuts(
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              },
              child: Actions(
                actions: {
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (_) {
                      onWordTap(word);
                      return null;
                    },
                  ),
                },
                child: InkWell(
                  key: AppKeys.readerWordToken(word, index),
                  borderRadius: BorderRadius.circular(4),
                  focusColor: Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.18),
                  onTap: () => onWordTap(word),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Text(
                      word,
                      style: textStyle?.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        decorationThickness: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (trailing.isNotEmpty) Text(trailing, style: textStyle),
      ],
    );
  }
}
