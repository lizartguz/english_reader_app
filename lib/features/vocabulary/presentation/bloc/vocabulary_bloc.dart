import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/vocabulary_entry.dart';
import '../../domain/repositories/vocabulary_repository.dart';

part 'vocabulary_event.dart';
part 'vocabulary_state.dart';

/// BLoC de listado y mantenimiento del vocabulario personal.
class VocabularyBloc extends Bloc<VocabularyEvent, VocabularyState> {
  VocabularyBloc(this._repository) : super(const VocabularyState.initial()) {
    on<VocabularyLoaded>(_onLoaded);
    on<VocabularyStatusChanged>(_onStatusChanged);
    on<VocabularyNotesChanged>(_onNotesChanged);
    on<VocabularyDeleted>(_onDeleted);
  }

  final VocabularyRepository _repository;

  /// Carga las palabras guardadas desde la API.
  Future<void> _onLoaded(
    VocabularyLoaded event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(state.copyWith(status: VocabularyStatus.loading));
    try {
      final entries = await _repository.listVocabulary();
      emit(
        state.copyWith(
          status: entries.isEmpty
              ? VocabularyStatus.empty
              : VocabularyStatus.success,
          entries: entries,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: VocabularyStatus.error,
          message: AppException.fromUnknown(error).message,
        ),
      );
    }
  }

  /// Cambia el estado de aprendizaje según los valores aceptados por la API.
  Future<void> _onStatusChanged(
    VocabularyStatusChanged event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(state.copyWith(busyEntryId: event.id, message: null));
    try {
      final updated = await _repository.updateVocabulary(
        id: event.id,
        status: event.status,
      );
      emit(
        state.copyWith(
          entries: _replaceEntry(updated),
          message: 'Estado actualizado.',
          clearBusyEntry: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          message: AppException.fromUnknown(error).message,
          clearBusyEntry: true,
        ),
      );
    }
  }

  /// Guarda notas breves de estudio asociadas a una palabra.
  Future<void> _onNotesChanged(
    VocabularyNotesChanged event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(state.copyWith(busyEntryId: event.id, message: null));
    try {
      final updated = await _repository.updateVocabulary(
        id: event.id,
        notes: event.notes,
      );
      emit(
        state.copyWith(
          entries: _replaceEntry(updated),
          message: 'Nota guardada.',
          clearBusyEntry: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          message: AppException.fromUnknown(error).message,
          clearBusyEntry: true,
        ),
      );
    }
  }

  /// Elimina una palabra del vocabulario sin afectar el diccionario global.
  Future<void> _onDeleted(
    VocabularyDeleted event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(state.copyWith(busyEntryId: event.id, message: null));
    try {
      await _repository.deleteVocabulary(event.id);
      final entries = state.entries
          .where((entry) => entry.id != event.id)
          .toList(growable: false);
      emit(
        state.copyWith(
          status: entries.isEmpty ? VocabularyStatus.empty : state.status,
          entries: entries,
          message: 'Palabra eliminada.',
          clearBusyEntry: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          message: AppException.fromUnknown(error).message,
          clearBusyEntry: true,
        ),
      );
    }
  }

  /// Reemplaza una entrada manteniendo el orden visible del listado.
  List<VocabularyEntry> _replaceEntry(VocabularyEntry updated) {
    return state.entries
        .map((entry) => entry.id == updated.id ? updated : entry)
        .toList(growable: false);
  }
}
