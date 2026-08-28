import 'csrf_token_reader_stub.dart'
    if (dart.library.html) 'csrf_token_reader_web.dart'
    as implementation;

/// Lee la cookie CSRF cuando la plataforma permite acceder a cookies.
String? readCsrfToken(String cookieName) {
  return implementation.readCsrfToken(cookieName);
}
