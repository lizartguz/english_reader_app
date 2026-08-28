import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../app/config/app_config.dart';
import '../constants/app_messages.dart';
import '../constants/storage_keys.dart';
import '../errors/app_exception.dart';
import '../storage/device_identity_service.dart';
import '../storage/secure_storage_service.dart';

/// Cliente HTTP centralizado para consumir el contrato versionado de la API.
class ApiClient {
  ApiClient({
    required AppConfig config,
    required SecureStorageService secureStorage,
    required DeviceIdentityService deviceIdentity,
  }) : _secureStorage = secureStorage,
       _deviceIdentity = deviceIdentity,
       _dio = Dio(
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

  final Dio _dio;
  final SecureStorageService _secureStorage;
  final DeviceIdentityService _deviceIdentity;
  final StreamController<AppException> _sessionIssues =
      StreamController<AppException>.broadcast();
  bool _refreshing = false;

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
    final token = await _secureStorage.read(StorageKeys.accessToken);
    return token == null ? const {} : {'Authorization': 'Bearer $token'};
  }

  /// Adjunta el access token sin exponerlo a widgets ni repositorios.
  Future<void> _attachToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(StorageKeys.accessToken);
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

    if (canRefresh && await _refreshSession()) {
      final retryOptions = error.requestOptions;
      retryOptions.extra['retried'] = true;
      final token = await _secureStorage.read(StorageKeys.accessToken);
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

  /// Rota el refresh token usando el mismo `device_id` de la instalación.
  Future<bool> _refreshSession() async {
    if (_refreshing) return false;

    final refreshToken = await _secureStorage.read(StorageKeys.refreshToken);
    if (refreshToken == null || refreshToken.isEmpty) return false;

    _refreshing = true;
    try {
      final response = await _dio.post<dynamic>(
        '/auth/refresh',
        data: {
          'clientType': 'mobile',
          'refreshToken': refreshToken,
          'device': await _deviceIdentity.devicePayload(),
        },
        options: Options(extra: {'skipRefresh': true}),
      );
      final payload = ApiPayload<Map<String, dynamic>>.fromJson(response.data);
      final session = payload.data;
      final nextAccessToken = session?['accessToken'] as String?;
      final nextRefreshToken = session?['refreshToken'] as String?;

      if (nextAccessToken == null || nextRefreshToken == null) return false;

      await _secureStorage.write(StorageKeys.accessToken, nextAccessToken);
      await _secureStorage.write(StorageKeys.refreshToken, nextRefreshToken);
      return true;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  /// Evita refresh recursivo en endpoints que administran la propia sesión.
  bool _isAuthRefreshRequest(RequestOptions options) {
    if (options.extra['skipRefresh'] == true) return true;
    return options.path.contains('/auth/login') ||
        options.path.contains('/auth/refresh') ||
        options.path.contains('/auth/logout');
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
