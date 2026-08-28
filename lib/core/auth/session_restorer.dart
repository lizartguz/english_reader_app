/// Capacidad de recuperar la sesión sin volver a pedir credenciales.
///
/// Se declara como interfaz mínima para que la capa de datos no dependa del
/// cliente HTTP completo, y para poder sustituirla en pruebas.
abstract class SessionRestorer {
  /// Devuelve `true` si logró obtener un access token nuevo.
  Future<bool> restoreSession();
}
