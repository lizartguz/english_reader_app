import 'browser_url_sanitizer_stub.dart'
    if (dart.library.js_interop) 'browser_url_sanitizer_web.dart'
    as implementation;
import 'url_query_sanitizer.dart';

/// Limpia de la URL visible los parámetros sensibles usados una sola vez.
void removeSensitiveQueryParameterFromBrowserUrl(String parameterName) {
  implementation.removeSensitiveQueryParameterFromBrowserUrl(parameterName);
}

/// Lee un parámetro sensible desde la URL visible cuando existe navegador.
String? readSensitiveQueryParameterFromBrowserUrl(String parameterName) {
  return implementation.readSensitiveQueryParameterFromBrowserUrl(
    parameterName,
  );
}

/// Elimina un parámetro sensible de una URL normal o de una ruta hash.
String removeSensitiveQueryParameterFromUrl(
  String url, {
  required String parameterName,
}) {
  return stripQueryParameterFromUrl(url, parameterName: parameterName);
}

/// Lee un parámetro sensible de una URL normal o de una ruta hash.
String? readSensitiveQueryParameterFromUrl(
  String url, {
  required String parameterName,
}) {
  return readQueryParameterFromUrl(url, parameterName: parameterName);
}
