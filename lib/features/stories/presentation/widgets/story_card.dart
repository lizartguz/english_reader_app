import 'package:flutter/material.dart';

import '../../../../core/accessibility/app_semantics.dart';
import '../../../reader/domain/entities/reading_progress.dart';
import '../../domain/entities/story.dart';
import 'story_cover_image.dart';

/// Tarjeta resumida de una historia publicada.
class StoryCard extends StatelessWidget {
  const StoryCard({
    required this.story,
    required this.onTap,
    this.progress,
    super.key,
  });

  final Story story;
  final VoidCallback onTap;
  final ReadingProgress? progress;

  /// Construye una tarjeta estable para listas móviles y grids Web.
  @override
  Widget build(BuildContext context) {
    final cover = story.coverImage;
    final visibleGenres = story.genres.take(4).toList(growable: false);
    final hiddenGenreCount = story.genres.length - visibleGenres.length;

    return Semantics(
      button: true,
      label: AppSemantics.storyCard(
        title: story.title,
        readingLevel: story.readingLevel.name,
        estimatedMinutes: story.estimatedReadingMinutes,
        progressPercent: progress?.progressPercent,
        completed: progress?.completedAt != null,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 7,
                  child: StoryCoverImage(cover: cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(
                            label: Text(story.readingLevel.code),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          if (story.estimatedReadingMinutes != null)
                            Text('${story.estimatedReadingMinutes} min'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        story.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (story.summary != null &&
                          story.summary!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          story.summary!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final genre in visibleGenres)
                            Text(
                              '#${genre.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (hiddenGenreCount > 0) Text('+$hiddenGenreCount'),
                        ],
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 12),
                        _StoryProgress(progress: progress!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicador de avance de lectura mostrado dentro de la tarjeta.
class _StoryProgress extends StatelessWidget {
  const _StoryProgress({required this.progress});

  final ReadingProgress progress;

  /// Muestra el avance guardado o el estado completado de la historia.
  @override
  Widget build(BuildContext context) {
    final completed = progress.completedAt != null;
    final percent = progress.progressPercent.clamp(0, 100).toDouble();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              completed ? Icons.check_circle : Icons.play_circle_outline,
              size: 18,
              color: completed ? theme.colorScheme.primary : theme.hintColor,
            ),
            const SizedBox(width: 6),
            Text(
              completed ? 'Completada' : 'Continuar · ${percent.round()}%',
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: percent / 100, minHeight: 5),
        ),
      ],
    );
  }
}
