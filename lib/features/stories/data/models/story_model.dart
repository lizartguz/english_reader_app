import '../../domain/entities/story.dart';

class StoryModel extends Story {
  const StoryModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.status,
    required super.sortOrder,
    required super.readingLevel,
    required super.genres,
    required super.assets,
    super.author,
    super.summary,
    super.estimatedReadingMinutes,
    super.publishedAt,
    super.content,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      author: json['author'] as String?,
      summary: json['summary'] as String?,
      status: json['status'] as String? ?? '',
      estimatedReadingMinutes: json['estimatedReadingMinutes'] as int?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      publishedAt: _parseDate(json['publishedAt']),
      readingLevel: StoryReadingLevelModel.fromJson(
        json['readingLevel'] as Map<String, dynamic>,
      ),
      genres: (json['genres'] as List<dynamic>? ?? const [])
          .map((item) => StoryGenreModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      assets: (json['assets'] as List<dynamic>? ?? const [])
          .map((item) => StoryAssetModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      content: json['content'] as String?,
    );
  }
}

class StoryReadingLevelModel extends StoryReadingLevel {
  const StoryReadingLevelModel({
    required super.id,
    required super.code,
    required super.name,
  });

  factory StoryReadingLevelModel.fromJson(Map<String, dynamic> json) {
    return StoryReadingLevelModel(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class StoryGenreModel extends StoryGenre {
  const StoryGenreModel({
    required super.id,
    required super.code,
    required super.name,
  });

  factory StoryGenreModel.fromJson(Map<String, dynamic> json) {
    return StoryGenreModel(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class StoryAssetModel extends StoryAsset {
  const StoryAssetModel({
    required super.id,
    required super.type,
    required super.mimeType,
    required super.accessScope,
    required super.sortOrder,
    required super.downloadUrl,
    super.originalFileName,
  });

  factory StoryAssetModel.fromJson(Map<String, dynamic> json) {
    return StoryAssetModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      originalFileName: json['originalFileName'] as String?,
      mimeType: json['mimeType'] as String? ?? '',
      accessScope: json['accessScope'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      downloadUrl: json['downloadUrl'] as String? ?? '',
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
