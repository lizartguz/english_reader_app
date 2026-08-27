import '../constants/app_messages.dart';

class AppException implements Exception {
  const AppException({required this.message, this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  bool get isSessionInvalidated => code == 'session_invalidated';
  bool get isSessionExpired =>
      code == 'session_expired' ||
      code == 'token_expired' ||
      code == 'token_invalid' ||
      code == 'unauthenticated';
  bool get isForbidden => code == 'forbidden' || statusCode == 403;
  bool get isNotFound => code == 'not_found' || statusCode == 404;

  /// Normaliza errores desconocidos para que la UI nunca muestre detalles técnicos.
  factory AppException.fromUnknown(Object error) {
    if (error is AppException) return error;
    return const AppException(message: AppMessages.genericError);
  }

  @override
  String toString() => message;
}
