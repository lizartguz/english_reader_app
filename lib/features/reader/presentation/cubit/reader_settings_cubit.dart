import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/preferences_service.dart';

/// Estado local de preferencias visuales para la lectura.
class ReaderSettingsState extends Equatable {
  const ReaderSettingsState({
    this.fontScale = ReaderSettingsCubit.defaultFontScale,
    this.lineHeight = ReaderSettingsCubit.defaultLineHeight,
  });

  final double fontScale;
  final double lineHeight;

  /// Crea una copia con los cambios visuales aplicados.
  ReaderSettingsState copyWith({double? fontScale, double? lineHeight}) {
    return ReaderSettingsState(
      fontScale: fontScale ?? this.fontScale,
      lineHeight: lineHeight ?? this.lineHeight,
    );
  }

  @override
  List<Object?> get props => [fontScale, lineHeight];
}

/// Administra ajustes persistentes del lector que no son datos sensibles.
class ReaderSettingsCubit extends Cubit<ReaderSettingsState> {
  ReaderSettingsCubit(this._preferences) : super(const ReaderSettingsState());

  static const double defaultFontScale = 1;
  static const double defaultLineHeight = 1.45;
  static const double minFontScale = 0.85;
  static const double maxFontScale = 1.35;
  static const double minLineHeight = 1.25;
  static const double maxLineHeight = 1.8;

  final PreferencesService _preferences;

  /// Carga los ajustes guardados y corrige valores fuera de rango.
  void load() {
    emit(
      ReaderSettingsState(
        fontScale: _clampFontScale(
          _preferences.getDouble(
            StorageKeys.readerFontScale,
            defaultValue: defaultFontScale,
          ),
        ),
        lineHeight: _clampLineHeight(
          _preferences.getDouble(
            StorageKeys.readerLineHeight,
            defaultValue: defaultLineHeight,
          ),
        ),
      ),
    );
  }

  /// Persiste la escala de texto elegida por el lector.
  Future<void> setFontScale(double value) async {
    final fontScale = _clampFontScale(value);
    emit(state.copyWith(fontScale: fontScale));
    await _preferences.setDouble(StorageKeys.readerFontScale, fontScale);
  }

  /// Persiste la altura de línea elegida por el lector.
  Future<void> setLineHeight(double value) async {
    final lineHeight = _clampLineHeight(value);
    emit(state.copyWith(lineHeight: lineHeight));
    await _preferences.setDouble(StorageKeys.readerLineHeight, lineHeight);
  }

  /// Restaura los valores cómodos definidos por defecto.
  Future<void> reset() async {
    emit(const ReaderSettingsState());
    await Future.wait([
      _preferences.remove(StorageKeys.readerFontScale),
      _preferences.remove(StorageKeys.readerLineHeight),
    ]);
  }

  /// Limita la escala para mantener legibilidad y diseño estable.
  double _clampFontScale(double value) {
    return value.clamp(minFontScale, maxFontScale);
  }

  /// Limita el interlineado para evitar bloques demasiado compactos o dispersos.
  double _clampLineHeight(double value) {
    return value.clamp(minLineHeight, maxLineHeight);
  }
}
