import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/story.dart';
import '../../domain/repositories/stories_repository.dart';

part 'stories_event.dart';
part 'stories_state.dart';

class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  StoriesBloc(this._storiesRepository) : super(const StoriesState.initial()) {
    on<StoriesLoaded>(_onLoaded);
  }

  final StoriesRepository _storiesRepository;

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
