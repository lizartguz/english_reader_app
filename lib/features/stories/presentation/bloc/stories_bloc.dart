import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../reader/domain/entities/reading_progress.dart';
import '../../domain/entities/story.dart';
import '../../domain/repositories/stories_repository.dart';

part 'stories_event.dart';
part 'stories_state.dart';

class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  StoriesBloc(this._storiesRepository) : super(const StoriesState.initial()) {
    on<StoriesLoaded>(_onLoaded);
  }

  final StoriesRepository _storiesRepository;

  /// Obtiene el avance sin romper el listado si el progreso falla.
  Future<Map<String, ReadingProgress>> _loadProgress() async {
    try {
      final progress = await _storiesRepository.listReadingProgress();
      return {for (final item in progress) item.storyId: item};
    } catch (_) {
      return const {};
    }
  }

  Future<void> _onLoaded(
    StoriesLoaded event,
    Emitter<StoriesState> emit,
  ) async {
    emit(state.copyWith(status: StoriesStatus.loading));
    try {
      final stories = await _storiesRepository.listStories();
      emit(
        state.copyWith(
          status: stories.isEmpty ? StoriesStatus.empty : StoriesStatus.success,
          stories: stories,
          progressByStory: await _loadProgress(),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: StoriesStatus.error,
          message: AppException.fromUnknown(error).message,
        ),
      );
    }
  }
}
