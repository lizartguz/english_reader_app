import 'package:equatable/equatable.dart';

class ReadingProgress extends Equatable {
  const ReadingProgress({
    required this.id,
    required this.userId,
    required this.storyId,
    required this.progressPercent,
    this.lastPosition,
    this.completedAt,
    this.lastReadAt,
  });

  final String id;
  final String userId;
  final String storyId;
  final double progressPercent;
  final String? lastPosition;
  final DateTime? completedAt;
  final DateTime? lastReadAt;

  @override
  List<Object?> get props => [
    id,
    userId,
    storyId,
    progressPercent,
    lastPosition,
    completedAt,
    lastReadAt,
  ];
}
