class AppMessages {
  const AppMessages._();

  static const apiUnavailable =
      'No se pudo conectar con el servidor. Intentalo nuevamente en unos minutos.';
  static const sessionExpired =
      'Tu sesion ha expirado. Inicia sesion nuevamente.';
  static const sessionInvalidated =
      'Tu sesion fue cerrada porque se inicio en otro dispositivo.';
  static const forbidden = 'No tienes permiso para realizar esta accion.';
  static const genericError =
      'No se pudo completar la accion. Intentalo nuevamente.';
  static const storiesLoadError = 'No se pudieron cargar las historias.';
  static const storyLoadError = 'No se pudo cargar la historia.';
  static const wordLookupError = 'No se pudo consultar la palabra.';
  static const vocabularySaved = 'Palabra guardada correctamente.';
}
