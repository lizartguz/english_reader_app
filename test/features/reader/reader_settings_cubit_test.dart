import 'package:english_reader_app/core/constants/storage_keys.dart';
import 'package:english_reader_app/core/storage/preferences_service.dart';
import 'package:english_reader_app/features/reader/presentation/cubit/reader_settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReaderSettingsCubit', () {
    test('carga valores guardados dentro del rango permitido', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.readerFontScale: 1.2,
        StorageKeys.readerLineHeight: 1.7,
      });
      final preferences = await PreferencesService.create();
      final cubit = ReaderSettingsCubit(preferences);

      cubit.load();

      expect(cubit.state.fontScale, 1.2);
      expect(cubit.state.lineHeight, 1.7);

      await cubit.close();
    });

    test('corrige valores fuera de rango al cargar', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.readerFontScale: 4.0,
        StorageKeys.readerLineHeight: 0.5,
      });
      final preferences = await PreferencesService.create();
      final cubit = ReaderSettingsCubit(preferences);

      cubit.load();

      expect(cubit.state.fontScale, ReaderSettingsCubit.maxFontScale);
      expect(cubit.state.lineHeight, ReaderSettingsCubit.minLineHeight);

      await cubit.close();
    });

    test('guarda y restablece las preferencias del lector', () async {
      final preferences = await PreferencesService.create();
      final cubit = ReaderSettingsCubit(preferences);

      await cubit.setFontScale(1.1);
      await cubit.setLineHeight(1.6);

      expect(cubit.state.fontScale, 1.1);
      expect(cubit.state.lineHeight, 1.6);

      await cubit.reset();

      expect(cubit.state.fontScale, ReaderSettingsCubit.defaultFontScale);
      expect(cubit.state.lineHeight, ReaderSettingsCubit.defaultLineHeight);

      await cubit.close();
    });
  });
}
