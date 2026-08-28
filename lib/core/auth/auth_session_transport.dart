import 'package:flutter/foundation.dart';

/// Define cómo viaja el refresh token según la plataforma actual.
class AuthSessionTransport {
  const AuthSessionTransport({bool isWeb = kIsWeb}) : _isWeb = isWeb;

  final bool _isWeb;

  /// Tipo de cliente esperado por la API para emitir la sesión correcta.
  String get clientType => _isWeb ? 'app_web' : 'mobile';

  /// En Web el refresh token vive en cookie HttpOnly, no en storage local.
  bool get usesCookieRefresh => _isWeb;
}
