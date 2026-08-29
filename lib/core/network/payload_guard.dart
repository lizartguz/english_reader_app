import '../constants/app_messages.dart';
import '../errors/app_exception.dart';

const invalidPayloadCode = 'invalid_payload';

/// Construye un error controlado cuando la API rompe el contrato JSON esperado.
AppException invalidPayloadException({
  String message = AppMessages.genericError,
}) {
  return AppException(message: message, code: invalidPayloadCode);
}

/// Exige un mapa JSON antes de acceder a campos anidados del payload.
Map<String, dynamic> requirePayloadMap(
  Object? value, {
  String message = AppMessages.genericError,
}) {
  if (value is Map<String, dynamic>) return value;
  throw invalidPayloadException(message: message);
}

/// Lee un mapa JSON opcional sin permitir tipos inesperados.
Map<String, dynamic>? optionalPayloadMap(
  Object? value, {
  String message = AppMessages.genericError,
}) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  throw invalidPayloadException(message: message);
}

/// Exige una lista JSON antes de recorrer colecciones del payload.
List<dynamic> requirePayloadList(
  Object? value, {
  String message = AppMessages.genericError,
}) {
  if (value is List<dynamic>) return value;
  throw invalidPayloadException(message: message);
}

/// Exige que un campo anidado exista como mapa JSON.
Map<String, dynamic> requirePayloadMapField(
  Map<String, dynamic> json,
  String field, {
  String message = AppMessages.genericError,
}) {
  return requirePayloadMap(json[field], message: message);
}

/// Lee cadenas opcionales evitando casteos directos sobre datos externos.
String? optionalPayloadString(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}

/// Convierte fallos de parseo de modelos en errores amigables para la app.
T parseApiPayload<T>(
  T Function() parser, {
  String message = AppMessages.genericError,
}) {
  try {
    return parser();
  } on AppException {
    rethrow;
  } on FormatException {
    throw invalidPayloadException(message: message);
  } on TypeError {
    throw invalidPayloadException(message: message);
  } on ArgumentError {
    throw invalidPayloadException(message: message);
  }
}
