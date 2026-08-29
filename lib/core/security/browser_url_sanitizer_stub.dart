/// En plataformas nativas no existe una barra de URL del navegador que limpiar.
void removeSensitiveQueryParameterFromBrowserUrl(String parameterName) {}

/// En nativo el token inicial llega por navegación interna, no por `window`.
String? readSensitiveQueryParameterFromBrowserUrl(String parameterName) => null;
