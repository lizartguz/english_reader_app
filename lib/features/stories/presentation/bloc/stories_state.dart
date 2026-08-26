part of 'stories_bloc.dart';

enum StoriesStatus { initial, loading, success, empty, error }

class StoriesState extends Equatable {
  const StoriesState({
    required this.status,
    this.stories = const [],
    this.message,
  });

  const StoriesState.initial()
    : status = StoriesStatus.initial,
      stories = const [],
      message = null;

  final StoriesStatus status;
  final List<Story> stories;
  final String? message;

  StoriesState copyWith({
    StoriesStatus? status,
    List<Story>? stories,
    String? message,
  }) {
    return StoriesState(
      status: status ?? this.status,
      stories: stories ?? this.stories,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, stories, message];
}
