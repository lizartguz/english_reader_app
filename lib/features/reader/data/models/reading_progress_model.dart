import '../../domain/entities/reading_progress.dart';

class ReadingProgressModel extends ReadingProgress {
  const ReadingProgressModel({
    required super.id,
    required super.userId,
    required super.storyId,
    required super.progressPercent,
    super.lastPosition,
    super.completedAt,
    super.lastReadAt,
  });

  factory ReadingProgressModel.fromJson(Map<String, dynamic> json) {
    return ReadingProgressModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      storyId: json['storyId'] as String,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0,
      lastPosition: json['lastPosition'] as String?,
      completedAt: _parseDate(json['completedAt']),
      lastReadAt: _parseDate(json['lastReadAt']),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
