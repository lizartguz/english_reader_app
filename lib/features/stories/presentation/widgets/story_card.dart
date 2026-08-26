import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/accessibility/app_semantics.dart';
import '../../domain/entities/story.dart';

/// Tarjeta resumida de una historia publicada.
class StoryCard extends StatelessWidget {
  const StoryCard({required this.story, required this.onTap, super.key});

  final Story story;
  final VoidCallback onTap;

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
                  child: cover == null || cover.downloadUrl.isEmpty
                      ? ColoredBox(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.auto_stories, size: 42),
                        )
                      : CachedNetworkImage(
                          imageUrl: cover.downloadUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
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
