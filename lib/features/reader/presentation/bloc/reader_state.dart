part of 'reader_bloc.dart';

enum ReaderStatus { initial, loading, success, error }

enum WordLookupStatus { initial, loading, success, error }

class ReaderState extends Equatable {
  const ReaderState({
    required this.status,
    required this.wordStatus,
    this.story,
    this.progress,
    this.selectedWord,
    this.message,
    this.isSavingVocabulary = false,
    this.visibleProgressPercent = 0,
    this.lastVisiblePosition,
  });

  const ReaderState.initial()
    : status = ReaderStatus.initial,
      wordStatus = WordLookupStatus.initial,
      story = null,
      progress = null,
      selectedWord = null,
      message = null,
      isSavingVocabulary = false,
      visibleProgressPercent = 0,
      lastVisiblePosition = null;

  final ReaderStatus status;
  final WordLookupStatus wordStatus;
  final Story? story;
  final ReadingProgress? progress;
  final WordDetail? selectedWord;
  final String? message;
  final bool isSavingVocabulary;
  final double visibleProgressPercent;
  final String? lastVisiblePosition;

  /// Posición persistida o visual que debe restaurar la vista de lectura.
  String? get effectiveLastPosition =>
      lastVisiblePosition ?? progress?.lastPosition;

  ReaderState copyWith({
    ReaderStatus? status,
    WordLookupStatus? wordStatus,
    Story? story,
    ReadingProgress? progress,
    WordDetail? selectedWord,
    String? message,
    bool? isSavingVocabulary,
    bool clearSelectedWord = false,
    double? visibleProgressPercent,
    String? lastVisiblePosition,
  }) {
    return ReaderState(
      status: status ?? this.status,
      wordStatus: wordStatus ?? this.wordStatus,
      story: story ?? this.story,
      progress: progress ?? this.progress,
      selectedWord: clearSelectedWord
          ? null
          : selectedWord ?? this.selectedWord,
      message: message,
      isSavingVocabulary: isSavingVocabulary ?? this.isSavingVocabulary,
      visibleProgressPercent:
          visibleProgressPercent ?? this.visibleProgressPercent,
      lastVisiblePosition: lastVisiblePosition ?? this.lastVisiblePosition,
    );
  }

  @override
  List<Object?> get props => [
    status,
    wordStatus,
    story,
    progress,
    selectedWord,
    message,
    isSavingVocabulary,
    visibleProgressPercent,
    lastVisiblePosition,
  ];
}
