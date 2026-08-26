import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_messages.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../stories/domain/entities/story.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/entities/word_detail.dart';
import '../../domain/repositories/reader_repository.dart';

part 'reader_event.dart';
part 'reader_state.dart';

class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  ReaderBloc(this._readerRepository) : super(const ReaderState.initial()) {
    on<ReaderStarted>(_onStarted);
    on<ReaderWordSelected>(_onWordSelected);
    on<ReaderWordDismissed>(_onWordDismissed);
    on<ReaderVocabularySaved>(_onVocabularySaved);
    on<ReaderProgressPreviewChanged>(_onProgressPreviewChanged);
    on<ReaderProgressSaved>(_onProgressSaved);
  }

  final ReaderRepository _readerRepository;

  Future<void> _onStarted(
    ReaderStarted event,
    Emitter<ReaderState> emit,
  ) async {
    emit(state.copyWith(status: ReaderStatus.loading));
    try {
      final story = await _readerRepository.getStory(event.storyId);
      final progress = await _readerRepository.getProgress(event.storyId);
      emit(
        state.copyWith(
          status: ReaderStatus.success,
          story: story,
          progress: progress,
          visibleProgressPercent: progress?.progressPercent ?? 0,
          lastVisiblePosition: progress?.lastPosition,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ReaderStatus.error,
          message: AppException.fromUnknown(error).message,
        ),
      );
    }
  }

  Future<void> _onWordSelected(
    ReaderWordSelected event,
    Emitter<ReaderState> emit,
  ) async {
    emit(
      state.copyWith(
        wordStatus: WordLookupStatus.loading,
        clearSelectedWord: true,
        message: null,
      ),
    );
    try {
      final word = await _readerRepository.lookupWord(event.word);
      emit(
        state.copyWith(
          wordStatus: WordLookupStatus.success,
          selectedWord: word,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          wordStatus: WordLookupStatus.error,
          message: AppException.fromUnknown(error).message,
        ),
      );
    }
  }

  void _onWordDismissed(ReaderWordDismissed event, Emitter<ReaderState> emit) {
    emit(
      state.copyWith(
        wordStatus: WordLookupStatus.initial,
        clearSelectedWord: true,
        isSavingVocabulary: false,
      ),
    );
  }

  Future<void> _onVocabularySaved(
    ReaderVocabularySaved event,
    Emitter<ReaderState> emit,
  ) async {
    final story = state.story;
    final word = state.selectedWord;
    if (story == null || word == null || word.isSaved) return;

    emit(state.copyWith(isSavingVocabulary: true));
    try {
      final savedWord = await _readerRepository.saveVocabulary(
        wordEntryId: word.id,
        storyId: story.id,
      );
      emit(
        state.copyWith(
          selectedWord: savedWord,
          isSavingVocabulary: false,
          message: AppMessages.vocabularySaved,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isSavingVocabulary: false,
          message: AppException.fromUnknown(error).message,
        ),
      );
    }
  }

  /// Actualiza el avance visual sin esperar la persistencia remota.
  void _onProgressPreviewChanged(
    ReaderProgressPreviewChanged event,
    Emitter<ReaderState> emit,
  ) {
    emit(
      state.copyWith(
        visibleProgressPercent: event.progressPercent,
        lastVisiblePosition: event.lastPosition,
        message: null,
      ),
    );
  }

  /// Sincroniza el avance calculado por la UI con la API.
  Future<void> _onProgressSaved(
    ReaderProgressSaved event,
    Emitter<ReaderState> emit,
  ) async {
    final story = state.story;
    if (story == null) return;

    try {
      final progress = await _readerRepository.saveProgress(
        storyId: story.id,
        progressPercent: event.progressPercent,
        lastPosition: event.lastPosition,
        completed: event.completed,
      );
      emit(
        state.copyWith(
          progress: progress,
          visibleProgressPercent: progress.progressPercent,
          lastVisiblePosition: progress.lastPosition,
          message: event.notify ? 'Progreso guardado.' : null,
        ),
      );
    } catch (error) {
      emit(state.copyWith(message: AppException.fromUnknown(error).message));
    }
  }
}
