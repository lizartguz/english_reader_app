import 'package:equatable/equatable.dart';

class Story extends Equatable {
  const Story({
    required this.id,
    required this.title,
    required this.slug,
    required this.status,
    required this.sortOrder,
    required this.readingLevel,
    required this.genres,
    required this.assets,
    this.author,
    this.summary,
    this.estimatedReadingMinutes,
    this.publishedAt,
    this.content,
  });

  final String id;
  final String title;
  final String slug;
  final String? author;
  final String? summary;
  final String status;
  final int sortOrder;
  final int? estimatedReadingMinutes;
  final DateTime? publishedAt;
  final StoryReadingLevel readingLevel;
  final List<StoryGenre> genres;
  final List<StoryAsset> assets;
  final String? content;

  StoryAsset? get coverImage => _firstAssetOfType('cover_image');

  /// Narración publicada por la API para escuchar la historia.
  StoryAsset? get audioAsset => _firstAssetOfType('audio');

  StoryAsset? _firstAssetOfType(String type) {
    for (final asset in assets) {
      if (asset.type == type) return asset;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    slug,
    author,
    summary,
    status,
    sortOrder,
    estimatedReadingMinutes,
    publishedAt,
    readingLevel,
    genres,
    assets,
    content,
  ];
}

class StoryReadingLevel extends Equatable {
  const StoryReadingLevel({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;

  @override
  List<Object?> get props => [id, code, name];
}

class StoryGenre extends Equatable {
  const StoryGenre({required this.id, required this.code, required this.name});

  final String id;
  final String code;
  final String name;

  @override
  List<Object?> get props => [id, code, name];
}

class StoryAsset extends Equatable {
  const StoryAsset({
    required this.id,
    required this.type,
    required this.mimeType,
    required this.accessScope,
    required this.sortOrder,
    required this.downloadUrl,
    this.originalFileName,
  });

  final String id;
  final String type;
  final String? originalFileName;
  final String mimeType;
  final String accessScope;
  final int sortOrder;
  final String downloadUrl;

  @override
  List<Object?> get props => [
    id,
    type,
    originalFileName,
    mimeType,
    accessScope,
    sortOrder,
    downloadUrl,
  ];
}
