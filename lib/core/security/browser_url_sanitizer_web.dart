import 'package:web/web.dart' as web;

import 'url_query_sanitizer.dart';

/// Reemplaza la entrada actual del historial para que el token no quede visible.
void removeSensitiveQueryParameterFromBrowserUrl(String parameterName) {
  final currentUrl = web.window.location.href;
  final sanitizedUrl = stripQueryParameterFromUrl(
    currentUrl,
    parameterName: parameterName,
  );

  if (sanitizedUrl == currentUrl) return;

  web.window.history.replaceState(null, '', sanitizedUrl);
}

/// Lee el parámetro desde la barra actual, incluyendo rutas hash de Flutter Web.
String? readSensitiveQueryParameterFromBrowserUrl(String parameterName) {
  return readQueryParameterFromUrl(
    web.window.location.href,
    parameterName: parameterName,
  );
}
