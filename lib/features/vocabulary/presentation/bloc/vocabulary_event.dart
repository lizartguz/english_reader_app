part of 'vocabulary_bloc.dart';

sealed class VocabularyEvent extends Equatable {
  const VocabularyEvent();

  @override
  List<Object?> get props => [];
}

class VocabularyLoaded extends VocabularyEvent {
  const VocabularyLoaded();
}

class VocabularyStatusChanged extends VocabularyEvent {
  const VocabularyStatusChanged({required this.id, required this.status});

  final String id;
  final String status;

  @override
  List<Object?> get props => [id, status];
}

class VocabularyNotesChanged extends VocabularyEvent {
  const VocabularyNotesChanged({required this.id, required this.notes});

  final String id;
  final String notes;

  @override
  List<Object?> get props => [id, notes];
}

class VocabularyDeleted extends VocabularyEvent {
  const VocabularyDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
