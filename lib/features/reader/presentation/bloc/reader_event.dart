part of 'reader_bloc.dart';

sealed class ReaderEvent extends Equatable {
  const ReaderEvent();

  @override
  List<Object?> get props => [];
}

class ReaderStarted extends ReaderEvent {
  const ReaderStarted(this.storyId);

  final String storyId;

  @override
  List<Object?> get props => [storyId];
}

class ReaderWordSelected extends ReaderEvent {
  const ReaderWordSelected(this.word);

  final String word;

  @override
  List<Object?> get props => [word];
}

class ReaderWordDismissed extends ReaderEvent {
  const ReaderWordDismissed();
}

class ReaderVocabularySaved extends ReaderEvent {
  const ReaderVocabularySaved();
}

class ReaderProgressPreviewChanged extends ReaderEvent {
  const ReaderProgressPreviewChanged({
    required this.progressPercent,
    this.lastPosition,
  });

  final double progressPercent;
  final String? lastPosition;

  @override
  List<Object?> get props => [progressPercent, lastPosition];
}

class ReaderProgressSaved extends ReaderEvent {
  const ReaderProgressSaved({
    required this.progressPercent,
    this.lastPosition,
    this.completed,
    this.notify = true,
  });

  final double progressPercent;
  final String? lastPosition;
  final bool? completed;
  final bool notify;

  @override
  List<Object?> get props => [progressPercent, lastPosition, completed, notify];
}
