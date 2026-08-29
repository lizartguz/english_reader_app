import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../app/config/app_config.dart';
import '../auth/auth_session_transport.dart';
import '../auth/session_restorer.dart';
import '../auth/session_token_store.dart';
import '../constants/app_messages.dart';
import '../errors/app_exception.dart';
import '../storage/device_identity_service.dart';
import 'csrf_token_reader.dart';

/// Cliente HTTP centralizado para consumir el contrato versionado de la API.
class ApiClient implements SessionRestorer {
  ApiClient({
    required AppConfig config,
    required AuthSessionTransport authSessionTransport,
    required SessionTokenStore tokenStore,
    required DeviceIdentityService deviceIdentity,
    @visibleForTesting Dio? dio,
  }) : _config = config,
       _authSessionTransport = authSessionTransport,
       _tokenStore = tokenStore,
       _deviceIdentity = deviceIdentity,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.apiBaseUrl,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 20),
               headers: const {
                 'Accept': 'application/json',
                 'Content-Type': 'application/json',
               },
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _attachToken, onError: _handleError),
    );
  }

  final AppConfig _config;
  final AuthSessionTransport _authSessionTransport;
  final Dio _dio;
  final SessionTokenStore _tokenStore;
  final DeviceIdentityService _deviceIdentity;
  final StreamController<AppException> _sessionIssues =
      StreamController<AppException>.broadcast();
  Future<bool>? _refreshFuture;

  /// Emite eventos cuando la API indica que la sesión local ya no sirve.
  Stream<AppException> get sessionIssues => _sessionIssues.stream;

  /// Ejecuta una consulta GET y normaliza la respuesta estándar de la API.
  Future<ApiPayload<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    return ApiPayload<T>.fromJson(response.data);
  }

  /// Descarga un recurso binario protegido reutilizando la sesión activa.
  Future<Uint8List> getBytes(String path) async {
    final response = await _dio.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  /// Ejecuta una solicitud POST y normaliza la respuesta estándar de la API.
  Future<ApiPayload<T>> post<T>(String path, {Object? data}) async {
    final response = await _dio.post<dynamic>(path, data: data);
    return ApiPayload<T>.fromJson(response.data);
  }

  /// Ejecuta una solicitud PATCH y normaliza la respuesta estándar de la API.
  Future<ApiPayload<T>> patch<T>(String path, {Object? data}) async {
    final response = await _dio.patch<dynamic>(path, data: data);
    return ApiPayload<T>.fromJson(response.data);
  }

  /// Ejecuta una solicitud DELETE y normaliza la respuesta estándar de la API.
  Future<ApiPayload<T>> delete<T>(String path) async {
    final response = await _dio.delete<dynamic>(path);
    return ApiPayload<T>.fromJson(response.data);
  }

  /// Devuelve cabeceras autenticadas para componentes que requieren URL directa.
  Future<Map<String, String>> authorizationHeaders() async {
    final token = await _tokenStore.readAccessToken();
    return token == null ? const {} : {'Authorization': 'Bearer $token'};
  }

  /// Recupera la sesión cuando no hay access token en memoria.
  ///
  /// En Web el access token se pierde a propósito al recargar la página; la
  /// cookie `HttpOnly` sigue viva, así que se pide uno nuevo antes de dar la
  /// sesión por terminada. En nativo no hace falta: el token está en el
  /// almacenamiento seguro.
  @override
  Future<bool> restoreSession() {
    if (!_authSessionTransport.usesCookieRefresh) return Future.value(false);
    return _refreshSession();
  }

  /// Adjunta el access token sin exponerlo a widgets ni repositorios.
  Future<void> _attachToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    _attachWebCookieOptions(options);
    final token = await _tokenStore.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// Intenta renovar una sesión vencida antes de propagar el error.
  Future<void> _handleError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = error.response?.statusCode;
    final code = _readErrorCode(error.response?.data);
    final canRefresh =
        statusCode == 401 &&
        code != 'session_invalidated' &&
        !_isAuthRefreshRequest(error.requestOptions) &&
        error.requestOptions.extra['retried'] != true;

    // Una petición enviada antes de la renovación puede llegar al servidor
    // después de ella: su 401 ya está resuelto y basta reintentarla con el token
    // vigente, sin rotar otra vez el refresh token.
    final tokenEnviado = error.requestOptions.headers['Authorization'];
    final tokenVigente = await _tokenStore.readAccessToken();
    final yaRenovado =
        tokenEnviado != null &&
        tokenVigente != null &&
        tokenEnviado != 'Bearer $tokenVigente';

    if (canRefresh && (yaRenovado || await _refreshSession())) {
      final retryOptions = error.requestOptions;
      retryOptions.extra['retried'] = true;
      final token = await _tokenStore.readAccessToken();
      if (token != null) {
        retryOptions.headers['Authorization'] = 'Bearer $token';
      }

      try {
        final response = await _dio.fetch<dynamic>(retryOptions);
        handler.resolve(response);
        return;
      } on DioException catch (retryError) {
        handler.reject(retryError);
        return;
      }
    }

    if (statusCode == 401) {
      _notifySessionIssue(error);
    }

    handler.reject(error);
  }

  /// Renueva la sesión una sola vez aunque varias peticiones fallen a la vez.
  ///
  /// Con una bandera booleana, la segunda petición que recibía 401 obtenía
  /// `false` de inmediato y terminaba cerrando la sesión, aunque la renovación
  /// en curso fuese a tener éxito. Compartir el mismo futuro evita ese cierre
  /// falso y, sobre todo, evita dos renovaciones simultáneas: usarían el mismo
  /// refresh token y la API lo trata como reutilización, revocando la sesión.
  Future<bool> _refreshSession() {
    return _refreshFuture ??= _performRefresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  /// Rota el refresh token usando el mismo `device_id` de la instalación.
  Future<bool> _performRefresh() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    final usesCookieRefresh = _authSessionTransport.usesCookieRefresh;
    if (!usesCookieRefresh && (refreshToken == null || refreshToken.isEmpty)) {
      return false;
    }

    try {
      final response = await _dio.post<dynamic>(
        '/auth/refresh',
        data: {
          'clientType': _authSessionTransport.clientType,
          if (!usesCookieRefresh) 'refreshToken': refreshToken,
          'device': await _deviceIdentity.devicePayload(),
        },
        options: Options(
          extra: {
            'skipRefresh': true,
            if (usesCookieRefresh) 'withCredentials': true,
          },
          headers: _csrfHeadersIfNeeded(),
        ),
      );
      final payload = ApiPayload<Map<String, dynamic>>.fromJson(response.data);
      final session = payload.data;
      final nextAccessToken = session?['accessToken'] as String?;
      final nextRefreshToken = session?['refreshToken'] as String?;

      if (nextAccessToken == null) return false;
      if (!usesCookieRefresh && nextRefreshToken == null) return false;

      await _tokenStore.writeAccessToken(nextAccessToken);
      await _tokenStore.writeRefreshToken(nextRefreshToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Evita refresh recursivo en endpoints que administran la propia sesión.
  bool _isAuthRefreshRequest(RequestOptions options) {
    if (options.extra['skipRefresh'] == true) return true;
    return options.path.contains('/auth/login') ||
        options.path.contains('/auth/refresh') ||
        options.path.contains('/auth/logout');
  }

  /// Habilita cookies y CSRF para Flutter Web sin afectar plataformas nativas.
  void _attachWebCookieOptions(RequestOptions options) {
    if (!_authSessionTransport.usesCookieRefresh) return;

    options.extra['withCredentials'] = true;
    final csrfHeaders = _csrfHeadersIfNeeded();
    if (csrfHeaders == null) return;

    options.headers.addAll(csrfHeaders);
  }

  /// Devuelve la cabecera CSRF cuando la cookie legible está disponible.
  Map<String, String>? _csrfHeadersIfNeeded() {
    if (!_authSessionTransport.usesCookieRefresh) return null;

    final csrfToken = readCsrfToken(_config.csrfCookieName);
    if (csrfToken == null || csrfToken.isEmpty) return null;

    return {'X-CSRF-Token': csrfToken};
  }

  /// Traduce errores 401 en eventos que la capa de auth puede observar.
  void _notifySessionIssue(DioException error) {
    final data = error.response?.data;
    final code = _readErrorCode(data);
    final message = code == 'session_invalidated'
        ? AppMessages.sessionInvalidated
        : AppMessages.sessionExpired;

    _sessionIssues.add(
      AppException(
        message: message,
        code: code,
        statusCode: error.response?.statusCode,
      ),
    );
  }
}

/// Respuesta JSON estándar `{ success, message, data, meta }`.
class ApiPayload<T> {
  const ApiPayload({
    required this.success,
    required this.message,
    required this.data,
    this.meta,
  });

  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? meta;

  /// Convierte la envoltura de la API en un objeto tipado.
  factory ApiPayload.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      throw const AppException(message: AppMessages.genericError);
    }

    final success = json['success'] == true;
    if (!success) {
      throw AppException(
        message: json['message'] as String? ?? AppMessages.genericError,
        code: json['code'] as String?,
      );
    }

    return ApiPayload<T>(
      success: success,
      message: json['message'] as String? ?? '',
      data: json['data'] as T?,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }
}

/// Lee el código estable de error cuando la API devuelve una respuesta controlada.
String? _readErrorCode(dynamic data) {
  if (data is Map<String, dynamic>) return data['code'] as String?;
  return null;
}

/// Convierte errores técnicos de red en mensajes amigables para la UI.
AppException mapDioException(Object error, String fallbackMessage) {
  if (error is AppException) return error;
  if (error is DioException) {
    final networkException = _mapNetworkException(error);
    if (networkException != null) return networkException;

    final data = error.response?.data;
    final statusCode = error.response?.statusCode;
    final code = _readErrorCode(data);

    if (data is Map<String, dynamic>) {
      return AppException(
        message: _friendlyApiMessage(
          statusCode: statusCode,
          code: code,
          rawMessage: data['message'],
          fallbackMessage: fallbackMessage,
        ),
        code: code,
        statusCode: statusCode,
      );
    }

    final statusException = _mapStatusException(
      statusCode: statusCode,
      code: code,
      fallbackMessage: fallbackMessage,
    );
    if (statusException != null) return statusException;
  }

  return AppException(message: fallbackMessage);
}

/// Traduce fallos de transporte antes de leer el cuerpo de la API.
AppException? _mapNetworkException(DioException error) {
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.badCertificate) {
    return const AppException(message: AppMessages.apiUnavailable);
  }

  if (error.type == DioExceptionType.cancel) {
    return const AppException(message: AppMessages.requestCancelled);
  }

  return null;
}

/// Decide el mensaje visible combinando estado HTTP y código estable de la API.
String _friendlyApiMessage({
  required int? statusCode,
  required String? code,
  required Object? rawMessage,
  required String fallbackMessage,
}) {
  if (statusCode != null && statusCode >= 500) {
    return fallbackMessage;
  }

  return _messageForCodeOrStatus(
        statusCode: statusCode,
        code: code,
        apiMessage: rawMessage is String && rawMessage.trim().isNotEmpty
            ? rawMessage.trim()
            : null,
      ) ??
      fallbackMessage;
}

/// Devuelve mensajes conocidos sin depender de textos cambiantes del backend.
String? _messageForCodeOrStatus({
  required int? statusCode,
  required String? code,
  String? apiMessage,
}) {
  switch (code) {
    case 'session_invalidated':
      return AppMessages.sessionInvalidated;
    case 'session_expired':
    case 'token_expired':
    case 'token_invalid':
    case 'unauthenticated':
      return AppMessages.sessionExpired;
    case 'forbidden':
      return AppMessages.forbidden;
    case 'not_found':
      return apiMessage ?? AppMessages.notFound;
    case 'conflict':
      return apiMessage ?? AppMessages.conflict;
    case 'validation_failed':
    case 'business_rule':
      return apiMessage ?? AppMessages.validationFailed;
    case 'rate_limited':
      return AppMessages.rateLimited;
    case 'external_provider_error':
    case 'external_provider_unavailable':
      return apiMessage ?? AppMessages.apiUnavailable;
  }

  switch (statusCode) {
    case 401:
      return AppMessages.sessionExpired;
    case 403:
      return AppMessages.forbidden;
    case 404:
      return apiMessage ?? AppMessages.notFound;
    case 409:
      return apiMessage ?? AppMessages.conflict;
    case 422:
      return apiMessage ?? AppMessages.validationFailed;
    case 429:
      return AppMessages.rateLimited;
  }

  return apiMessage;
}

/// Cubre errores HTTP sin cuerpo JSON normalizado.
AppException? _mapStatusException({
  required int? statusCode,
  required String? code,
  required String fallbackMessage,
}) {
  final message = _messageForCodeOrStatus(statusCode: statusCode, code: code);

  if (message != null) {
    return AppException(message: message, code: code, statusCode: statusCode);
  }

  if (statusCode != null && statusCode >= 500) {
    return AppException(message: fallbackMessage);
  }

  return null;
}
