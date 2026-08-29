import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:english_reader_app/app/config/app_config.dart';
import 'package:english_reader_app/core/auth/auth_session_transport.dart';
import 'package:english_reader_app/core/auth/session_token_store.dart';
import 'package:english_reader_app/core/constants/storage_keys.dart';
import 'package:english_reader_app/core/network/api_client.dart';
import 'package:english_reader_app/core/storage/device_identity_service.dart';
import 'package:english_reader_app/core/storage/secure_storage_service.dart';
import 'package:english_reader_app/core/telemetry/security_event.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renovación de sesión ante varios 401 simultáneos (hallazgo FLT-SEC-007).
void main() {
  group('ApiClient renovación concurrente', () {
    test('tres peticiones que fallan a la vez comparten una sola renovación', () async {
      final entorno = _crearEntorno();

      // Las tres salen con el token vencido y reciben 401 casi al mismo tiempo.
      final respuestas = await Future.wait([
        entorno.client.get<Map<String, dynamic>>('/app/stories'),
        entorno.client.get<Map<String, dynamic>>('/app/vocabulary'),
        entorno.client.get<Map<String, dynamic>>('/app/reading-progress'),
      ]);

      // Dos renovaciones simultáneas usarían el mismo refresh token y la API lo
      // trataría como reutilización, revocando la sesión completa.
      expect(entorno.adapter.renovaciones, 1);
      expect(respuestas.every((respuesta) => respuesta.success), isTrue);
      expect(await entorno.tokenStore.readAccessToken(), _tokenNuevo);
    });

    test('ninguna peticion se cierra en falso mientras otra renueva', () async {
      final entorno = _crearEntorno();

      // Antes, la segunda petición recibía `false` de la renovación en curso y
      // terminaba propagando un cierre de sesión que no correspondía.
      final eventos = <Object>[];
      final suscripcion = entorno.client.sessionIssues.listen(eventos.add);

      await Future.wait([
        entorno.client.get<Map<String, dynamic>>('/app/stories'),
        entorno.client.get<Map<String, dynamic>>('/app/vocabulary'),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await suscripcion.cancel();

      expect(eventos, isEmpty);
    });

    test('registra la incidencia de seguridad sin exponer la ruta concreta', () async {
      final entorno = _crearEntorno();

      // Se pide una ruta que la API rechaza por permisos: ese error si llega al
      // usuario y merece quedar registrado.
      entorno.adapter.rutaProhibida = '/app/stories/01a04b6f-ae19-74';
      try {
        await entorno.client.get<Map<String, dynamic>>('/app/stories/01a04b6f-ae19-74');
      } catch (_) {
        // El rechazo es el punto de la prueba; interesa lo que quedo registrado.
      }

      final eventos = entorno.client.telemetry.history;
      expect(eventos, isNotEmpty);
      expect(eventos.last.type, SecurityEventType.forbidden);
      // Con el identificador saneado: la ruta real diria que historia leyo.
      expect(eventos.last.endpoint, '/app/stories/{id}');
      expect(eventos.last.statusCode, 403);
    });

    test('una peticion rezagada se reintenta sin volver a renovar', () async {
      final entorno = _crearEntorno();
      // Su 401 tarda en volver: sale con el token viejo y llega cuando la
      // renovación disparada por otra petición ya termino.
      entorno.adapter.demoraDel401['/app/stories'] = const Duration(
        milliseconds: 150,
      );

      final rezagada = entorno.client.get<Map<String, dynamic>>('/app/stories');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await entorno.client.get<Map<String, dynamic>>('/app/vocabulary');
      expect(entorno.adapter.renovaciones, 1);

      // Al volver, el token ya cambió: basta reintentar con el vigente en vez
      // de rotar otra vez el refresh token sin necesidad.
      expect((await rezagada).success, isTrue);
      expect(entorno.adapter.renovaciones, 1);
    });
  });
}

const _tokenViejo = 'access-vencido';
const _tokenNuevo = 'access-renovado';

_Entorno _crearEntorno() {
  final almacenamiento = _FakeSecureStorage()
    ..values[StorageKeys.accessToken] = _tokenViejo
    ..values[StorageKeys.refreshToken] = 'refresh-vigente';

  const transporte = AuthSessionTransport(isWeb: false);
  final tokenStore = SessionTokenStore(
    transport: transporte,
    secureStorage: almacenamiento,
  );

  final config = AppConfig.resolve(apiBaseUrl: 'https://api.test.local/api/v1');
  final adapter = _AdapterFalso();
  final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl))
    ..httpClientAdapter = adapter;

  final client = ApiClient(
    config: config,
    authSessionTransport: transporte,
    tokenStore: tokenStore,
    deviceIdentity: DeviceIdentityService(
      secureStorage: almacenamiento,
      config: config,
    ),
    dio: dio,
  );

  return _Entorno(client: client, adapter: adapter, tokenStore: tokenStore);
}

class _Entorno {
  _Entorno({
    required this.client,
    required this.adapter,
    required this.tokenStore,
  });

  final ApiClient client;
  final _AdapterFalso adapter;
  final SessionTokenStore tokenStore;
}

/// Servidor simulado: rechaza el token viejo y renueva con latencia.
class _AdapterFalso implements HttpClientAdapter {
  int renovaciones = 0;
  String? rutaProhibida;
  final demoraDel401 = <String, Duration>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/auth/refresh')) {
      renovaciones += 1;
      // La latencia es deliberada: sin ella las peticiones no llegarían a
      // solaparse y la prueba pasaría incluso con el error original.
      await Future<void>.delayed(const Duration(milliseconds: 40));
      return _json(200, {
        'success': true,
        'message': 'ok',
        'data': {'accessToken': _tokenNuevo, 'refreshToken': 'refresh-rotado'},
      });
    }

    if (options.path == rutaProhibida) {
      return _json(403, {
        'success': false,
        'message': 'Sin permisos.',
        'code': 'forbidden',
      });
    }

    if (options.headers['Authorization'] == 'Bearer $_tokenNuevo') {
      return _json(200, {
        'success': true,
        'message': 'ok',
        'data': {'ruta': options.path},
      });
    }

    final demora = demoraDel401[options.path];
    if (demora != null) await Future<void>.delayed(demora);

    return _json(401, {
      'success': false,
      'message': 'La sesión expiró.',
      'code': 'token_expired',
    });
  }

  ResponseBody _json(int status, Map<String, dynamic> cuerpo) {
    return ResponseBody.fromString(
      jsonEncode(cuerpo),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeSecureStorage implements SecureStorageService {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
