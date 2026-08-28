import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/media/story_asset_loader.dart';
import '../../domain/entities/story.dart';

/// Portada de historia descargada con la sesión activa del usuario.
class StoryCoverImage extends StatefulWidget {
  const StoryCoverImage({required this.cover, super.key});

  final StoryAsset? cover;

  @override
  State<StoryCoverImage> createState() => _StoryCoverImageState();
}

class _StoryCoverImageState extends State<StoryCoverImage> {
  Future<Uint8List>? _bytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCover();
  }

  @override
  void didUpdateWidget(covariant StoryCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cover?.id != widget.cover?.id) {
      _bytes = null;
      _loadCover();
    }
  }

  /// Muestra la portada real o un marcador estable con la marca de la app.
  @override
  Widget build(BuildContext context) {
    final request = _bytes;
    if (request == null) return const _CoverPlaceholder();

    return FutureBuilder<Uint8List>(
      future: request,
      builder: (context, snapshot) {
        if (snapshot.hasError || snapshot.data == null) {
          return const _CoverPlaceholder();
        }
        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const _CoverPlaceholder(),
        );
      },
    );
  }

  /// Solicita la portada solo cuando la historia declara una imagen.
  void _loadCover() {
    final cover = widget.cover;
    if (cover == null || _bytes != null) return;
    _bytes = context.read<StoryAssetLoader>().load(cover.id);
  }
}

/// Marcador usado cuando la historia no tiene portada disponible.
class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  /// Mantiene el mismo bloque visual aunque falte la imagen.
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Icon(Icons.auto_stories, size: 42),
    );
  }
}
