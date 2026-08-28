part of 'stories_bloc.dart';

enum StoriesStatus { initial, loading, success, empty, error }

class StoriesState extends Equatable {
  const StoriesState({
    required this.status,
    this.stories = const [],
    this.progressByStory = const {},
    this.message,
  });

  const StoriesState.initial()
    : status = StoriesStatus.initial,
      stories = const [],
      progressByStory = const {},
      message = null;

  final StoriesStatus status;
  final List<Story> stories;
  final Map<String, ReadingProgress> progressByStory;
  final String? message;

  StoriesState copyWith({
    StoriesStatus? status,
    List<Story>? stories,
    Map<String, ReadingProgress>? progressByStory,
    String? message,
  }) {
    return StoriesState(
      status: status ?? this.status,
      stories: stories ?? this.stories,
      progressByStory: progressByStory ?? this.progressByStory,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, stories, progressByStory, message];
}
