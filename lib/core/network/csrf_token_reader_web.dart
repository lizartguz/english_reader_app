import 'package:web/web.dart' as web;

/// Lee una cookie visible del navegador para repetirla como cabecera CSRF.
String? readCsrfToken(String cookieName) {
  final cookieHeader = web.document.cookie;
  if (cookieHeader.isEmpty) return null;

  for (final rawCookie in cookieHeader.split(';')) {
    final cookie = rawCookie.trim();
    final separatorIndex = cookie.indexOf('=');
    if (separatorIndex <= 0) continue;

    final name = cookie.substring(0, separatorIndex);
    if (name != cookieName) continue;

    return Uri.decodeComponent(cookie.substring(separatorIndex + 1));
  }

  return null;
}
