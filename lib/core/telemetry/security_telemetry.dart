import 'dart:async';
import 'dart:collection';

import '../auth/session_scoped_cache.dart';
import 'security_event.dart';

/// Canal de eventos de seguridad del cliente.
///
/// Existe para poder responder preguntas que hoy se pierden: si los 401 se
/// disparan de golpe, si la renovación de sesión falla a menudo, si la API deja
/// de responder para un grupo de usuarios. Los errores se convertían en un
/// mensaje de pantalla y ahí terminaban.
///
/// **No envía nada a ningún servidor.** Publica los eventos en memoria para que
/// alguien los consuma: hoy solo el historial reciente, que sirve para
/// diagnosticar en una sesión de soporte. Enviarlos a un servicio externo sería
/// una decisión aparte, con su propia conversación sobre privacidad.
class SecurityTelemetry implements SessionScopedCache {
  SecurityTelemetry({this.maxHistory = 50});

  /// Cuántos eventos recientes se conservan. Acotado a propósito: es un
  /// diagnóstico, no un registro histórico, y no debe crecer sin límite.
  final int maxHistory;

  final _controller = StreamController<SecurityEvent>.broadcast();
  final Queue<SecurityEvent> _history = Queue<SecurityEvent>();

  /// Eventos según ocurren, para quien quiera reaccionar en vivo.
  Stream<SecurityEvent> get events => _controller.stream;

  /// Últimos eventos, del más antiguo al más reciente.
  List<SecurityEvent> get history => List.unmodifiable(_history);

  /// Registra un evento ya saneado.
  void record(
    SecurityEventType type, {
    String? endpoint,
    int? statusCode,
    String? errorCode,
  }) {
    final event = SecurityEvent(
      type: type,
      // El saneado se hace aquí y no en quien llama, para que ninguna ruta con
      // identificadores se cuele por olvido.
      endpoint: endpoint == null ? null : sanitizeEndpoint(endpoint),
      statusCode: statusCode,
      errorCode: errorCode,
    );

    _history.addLast(event);
    while (_history.length > maxHistory) {
      _history.removeFirst();
    }

    if (!_controller.isClosed) _controller.add(event);
  }

  /// Descarta el historial. Se llama al cerrar sesión: los eventos son de la
  /// sesión que termina y no deben mezclarse con los de quien entre después.
  @override
  void clear() => _history.clear();

  Future<void> dispose() async {
    _history.clear();
    await _controller.close();
  }
}
