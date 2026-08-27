import 'dart:io';

import 'package:dio/dio.dart';

/// Verifica el flujo real Flutter -> API sin guardar tokens en disco.
Future<void> main(List<String> args) async {
  final options = VerifyRealApiOptions.parse(args);
  final verifier = RealApiFlowVerifier(options);

  try {
    final result = await verifier.run();
    stdout.writeln('OK login: ${result.userEmail}');
    stdout.writeln('OK historia: ${result.storyTitle}');
    stdout.writeln('OK lookup: ${result.word}');
    stdout.writeln('OK vocabulario: ${result.vocabularyMessage}');
  } catch (error) {
    stderr.writeln(
      'Fallo la verificacion real de API: ${_friendlyError(error)}',
    );
    exitCode = 1;
  }
}

/// Opciones CLI para ejecutar el smoke real en local o staging.
class VerifyRealApiOptions {
  const VerifyRealApiOptions({
    required this.baseUrl,
    required this.email,
    required this.password,
    required this.word,
  });

  final String baseUrl;
  final String email;
  final String password;
  final String word;

  /// Lee argumentos simples `--clave=valor` con defaults de desarrollo local.
  factory VerifyRealApiOptions.parse(List<String> args) {
    final values = <String, String>{};
    for (final arg in args) {
      if (!arg.startsWith('--') || !arg.contains('=')) continue;
      final index = arg.indexOf('=');
      values[arg.substring(2, index)] = arg.substring(index + 1);
    }

    return VerifyRealApiOptions(
      baseUrl: values['base-url'] ?? 'http://localhost:3000/api/v1',
      email: values['email'] ?? 'cliente.flutter.test@englishreader.local',
      password: values['password'] ?? 'Cliente123*',
      word: values['word'] ?? 'hello',
    );
  }
}

/// Resultado resumido sin exponer access token ni refresh token.
class RealApiFlowResult {
  const RealApiFlowResult({
    required this.userEmail,
    required this.storyTitle,
    required this.word,
    required this.vocabularyMessage,
  });

  final String userEmail;
  final String storyTitle;
  final String word;
  final String vocabularyMessage;
}

/// Ejecuta login, historias, lookup y guardado de vocabulario contra la API real.
class RealApiFlowVerifier {
  RealApiFlowVerifier(this.options)
    : _dio = Dio(
        BaseOptions(
          baseUrl: options.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

  final VerifyRealApiOptions options;
  final Dio _dio;

  /// Recorre el flujo principal que Flutter necesita para iniciar lectura.
  Future<RealApiFlowResult> run() async {
    final login = await _post('/auth/login', {
      'email': options.email,
      'password': options.password,
      'clientType': 'mobile',
      'device': {
        'deviceId': 'flutter-real-api-verifier',
        'platform': Platform.operatingSystem,
        'appVersion': 'tool',
      },
    });

    final session = _map(login['data'], 'data');
    final token = _string(session['accessToken'], 'accessToken');
    final user = _map(session['user'], 'user');
    _dio.options.headers['Authorization'] = 'Bearer $token';

    final stories = await _get('/app/stories', queryParameters: {'limit': 1});
    final story = _firstMap(stories['data'], 'data');
    final storyId = _string(story['id'], 'story.id');

    final lookup = await _get(
      '/app/words/lookup',
      queryParameters: {'word': options.word},
    );
    final word = _map(lookup['data'], 'data');

    final vocabulary = await _post('/app/vocabulary', {
      'wordEntryId': _string(word['id'], 'word.id'),
      'storyId': storyId,
    });

    return RealApiFlowResult(
      userEmail: _string(user['email'], 'user.email'),
      storyTitle: _string(story['title'], 'story.title'),
      word: _string(word['word'], 'word.word'),
      vocabularyMessage: _string(vocabulary['message'], 'message'),
    );
  }

  /// Ejecuta GET y valida la envoltura estándar de la API.
  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    return _payload(response.data);
  }

  /// Ejecuta POST y valida la envoltura estándar de la API.
  Future<Map<String, dynamic>> _post(String path, Object data) async {
    final response = await _dio.post<dynamic>(path, data: data);
    return _payload(response.data);
  }
}

/// Valida la respuesta `{ success, message, data }` antes de continuar.
Map<String, dynamic> _payload(dynamic data) {
  final payload = _map(data, 'payload');
  if (payload['success'] != true) {
    throw StateError(_string(payload['message'], 'message'));
  }
  return payload;
}

/// Extrae un mapa tipado y falla con un nombre de campo claro.
Map<String, dynamic> _map(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  throw StateError('Respuesta invalida: $field no es un objeto.');
}

/// Extrae el primer mapa de una lista devuelta por la API.
Map<String, dynamic> _firstMap(Object? value, String field) {
  if (value is List &&
      value.isNotEmpty &&
      value.first is Map<String, dynamic>) {
    return value.first as Map<String, dynamic>;
  }
  throw StateError('Respuesta invalida: $field no contiene elementos.');
}

/// Extrae strings obligatorios sin propagar `null` al resto del flujo.
String _string(Object? value, String field) {
  if (value is String && value.isNotEmpty) return value;
  throw StateError('Respuesta invalida: $field no es texto.');
}

/// Muestra errores de red/API sin exponer tokens ni cuerpos completos.
String _friendlyError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return error.message ?? error.type.name;
  }
  return error.toString();
}
