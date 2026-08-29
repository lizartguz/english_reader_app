/// Tipos de evento de seguridad que la app observa en el cliente.
enum SecurityEventType {
  /// Credenciales rechazadas al iniciar sesión.
  loginRejected,

  /// La sesión caducó y hubo que renovarla o cerrarla.
  sessionExpired,

  /// La sesión se cerró desde otro dispositivo.
  sessionInvalidated,

  /// La renovación con el refresh token no prosperó.
  refreshFailed,

  /// La API no respondió: red caída, timeout o CORS.
  apiUnavailable,

  /// La API rechazó la operación por permisos.
  forbidden,

  /// La API aplicó su límite de peticiones.
  rateLimited,

  /// No se pudo descargar un recurso privado de una historia.
  assetLoadFailed,
}

/// Evento de seguridad ya saneado, listo para registrarse.
///
/// Solo lleva datos que no identifican a nadie: el tipo de evento, el código
/// que devolvió la API, el estado HTTP y la ruta con sus identificadores
/// sustituidos. **Nunca** lleva tokens, correos, contraseñas ni el mensaje de
/// la respuesta, que puede incluir datos del usuario.
class SecurityEvent {
  SecurityEvent({
    required this.type,
    this.endpoint,
    this.statusCode,
    this.errorCode,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  final SecurityEventType type;

  /// Ruta con los identificadores sustituidos por `{id}`.
  final String? endpoint;
  final int? statusCode;

  /// Código de error de la API (`token_expired`, `rate_limited`…), no su texto.
  final String? errorCode;
  final DateTime at;

  @override
  String toString() {
    final partes = <String>[
      type.name,
      if (statusCode != null) 'status=$statusCode',
      if (errorCode != null) 'code=$errorCode',
      if (endpoint != null) 'endpoint=$endpoint',
    ];
    return 'SecurityEvent(${partes.join(' ')})';
  }
}

/// Sustituye por `{id}` los segmentos de ruta que parecen identificadores.
///
/// Sin esto, la telemetría revelaría qué historia leyó o qué palabra consultó
/// una persona concreta, que es justo el tipo de dato que no debe registrarse.
String sanitizeEndpoint(String path) {
  final sinQuery = path.split('?').first;

  return sinQuery
      .split('/')
      .map((segmento) => _pareceIdentificador(segmento) ? '{id}' : segmento)
      .join('/');
}

bool _pareceIdentificador(String segmento) {
  if (segmento.length < 8) return false;

  // UUID, ULID o cualquier cadena larga con dígitos: no es un nombre de ruta.
  final tieneDigito = RegExp(r'\d').hasMatch(segmento);
  final soloIdentificador = RegExp(r'^[A-Za-z0-9._~-]+$').hasMatch(segmento);

  return tieneDigito && soloIdentificador;
}
