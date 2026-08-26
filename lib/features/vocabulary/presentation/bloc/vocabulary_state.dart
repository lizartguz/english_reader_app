part of 'vocabulary_bloc.dart';

enum VocabularyStatus { initial, loading, success, empty, error }

/// Estado de pantalla para el vocabulario personal.
class VocabularyState extends Equatable {
  const VocabularyState({
    required this.status,
    this.entries = const [],
    this.message,
    this.busyEntryId,
  });

  const VocabularyState.initial()
    : status = VocabularyStatus.initial,
      entries = const [],
      message = null,
      busyEntryId = null;

  final VocabularyStatus status;
  final List<VocabularyEntry> entries;
  final String? message;
  final String? busyEntryId;

  /// Devuelve un nuevo estado conservando datos ya cargados.
  VocabularyState copyWith({
    VocabularyStatus? status,
    List<VocabularyEntry>? entries,
    String? message,
    String? busyEntryId,
    bool clearBusyEntry = false,
  }) {
    return VocabularyState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      message: message,
      busyEntryId: clearBusyEntry ? null : busyEntryId ?? this.busyEntryId,
    );
  }

  @override
  List<Object?> get props => [status, entries, message, busyEntryId];
}
