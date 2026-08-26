import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  const PreferencesService._(this._preferences);

  final SharedPreferences _preferences;

  /// Crea el adaptador local para preferencias no sensibles de la app.
  static Future<PreferencesService> create() async {
    return PreferencesService._(await SharedPreferences.getInstance());
  }

  /// Lee una preferencia booleana con valor seguro por defecto.
  bool getBool(String key, {bool defaultValue = false}) {
    return _preferences.getBool(key) ?? defaultValue;
  }

  /// Guarda una preferencia booleana no sensible.
  Future<void> setBool(String key, bool value) {
    return _preferences.setBool(key, value);
  }

  /// Lee una preferencia decimal usada por ajustes visuales locales.
  double getDouble(String key, {required double defaultValue}) {
    return _preferences.getDouble(key) ?? defaultValue;
  }

  /// Guarda una preferencia decimal no sensible.
  Future<void> setDouble(String key, double value) {
    return _preferences.setDouble(key, value);
  }

  /// Elimina una preferencia local cuando debe volver a su valor inicial.
  Future<void> remove(String key) => _preferences.remove(key);
}
