import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../app/config/app_config.dart';
import '../constants/storage_keys.dart';
import 'secure_storage_service.dart';

class DeviceIdentityService {
  DeviceIdentityService({
    required SecureStorageService secureStorage,
    required AppConfig config,
  }) : _secureStorage = secureStorage,
       _config = config;

  final SecureStorageService _secureStorage;
  final AppConfig _config;

  /// Identificador estable que la API usa para aplicar un dispositivo activo.
  Future<String> getOrCreateDeviceId() async {
    final current = await _secureStorage.read(StorageKeys.deviceId);
    if (current != null && current.isNotEmpty) return current;

    final created = const Uuid().v4();
    await _secureStorage.write(StorageKeys.deviceId, created);
    return created;
  }

  Future<Map<String, String>> devicePayload() async {
    return {
      'deviceId': await getOrCreateDeviceId(),
      'platform': _platformName,
      'appVersion': _config.appVersion,
    };
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
