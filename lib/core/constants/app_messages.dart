class AppMessages {
  const AppMessages._();

  static const apiUnavailable =
      'No se pudo conectar con el servidor. Intentalo nuevamente en unos minutos.';
  static const requestCancelled =
      'La solicitud fue cancelada. Intentalo nuevamente.';
  static const sessionExpired =
      'Tu sesion ha expirado. Inicia sesion nuevamente.';
  static const sessionInvalidated =
      'Tu sesion fue cerrada porque se inicio en otro dispositivo.';
  static const forbidden = 'No tienes permiso para realizar esta accion.';
  static const notFound = 'No se encontro la informacion solicitada.';
  static const conflict =
      'La operacion no puede completarse con el estado actual.';
  static const rateLimited =
      'Demasiadas solicitudes. Espera unos segundos e intentalo nuevamente.';
  static const validationFailed =
      'Revisa los datos enviados e intentalo nuevamente.';
  static const genericError =
      'No se pudo completar la accion. Intentalo nuevamente.';
  static const registerError = 'No se pudo crear la cuenta.';
  static const passwordResetError =
      'No se pudo completar la recuperación de contraseña.';
  static const storiesLoadError = 'No se pudieron cargar las historias.';
  static const storyLoadError = 'No se pudo cargar la historia.';
  static const progressLoadError = 'No se pudo cargar tu progreso de lectura.';
  static const wordLookupError = 'No se pudo consultar la palabra.';
  static const assetLoadError = 'No se pudo cargar el recurso de la historia.';
  static const vocabularySaved = 'Palabra guardada correctamente.';
}
