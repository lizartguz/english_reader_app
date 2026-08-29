/// Caché en memoria cuyo contenido pertenece a la sesión actual.
///
/// Lo implementan las cachés que guardan datos privados de un usuario, para que
/// la capa de autenticación pueda vaciarlas sin conocerlas en detalle: al
/// cerrar sesión, al expirar, y al iniciar sesión con otra cuenta en el mismo
/// proceso.
abstract class SessionScopedCache {
  /// Libera todo lo que se descargó con la sesión anterior.
  void clear();
}
