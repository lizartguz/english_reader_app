# Guía de renovación de sesión

## Para qué sirve

El access token dura 15 minutos. Cuando vence, la API responde **401** a
cualquier petición. En vez de mandar al usuario al login cada cuarto de hora,
`ApiClient` intercepta ese 401, pide un token nuevo y **reintenta la petición
original**. Si todo sale bien, la pantalla ni se entera.

Lo delicado no es renovar: es que la app dispara **varias peticiones a la vez**
—el arranque pide historias, vocabulario y progreso juntos— y cuando el token
vence, las tres fallan casi en el mismo instante. La renovación tiene que
resolver eso sin renovar tres veces ni cerrar la sesión por error.

---

## Dónde está

Todo vive en un solo archivo: [`lib/core/network/api_client.dart`](../lib/core/network/api_client.dart).

| Elemento | Rol |
|---|---|
| `_attachToken` | Interceptor de salida: pone el `Authorization` en cada petición. |
| `_handleError` | Interceptor de error: decide si un 401 se puede recuperar. |
| `_refreshSession` | Puerta de entrada a la renovación. Es quien serializa. |
| `_performRefresh` | La renovación real contra `POST /auth/refresh`. |
| `restoreSession` | Entrada pública, usada al arrancar en Web. Ver [guia-sesion-web-tokens.md](guia-sesion-web-tokens.md). |

Piezas relacionadas: `SessionTokenStore` guarda el token resultante y
`AuthSessionTransport` decide si el refresh viaja por cookie o en el cuerpo.

---

## Cómo funciona

### La regla clave: una sola renovación compartida

```dart
Future<bool> _refreshSession() {
  return _refreshFuture ??= _performRefresh().whenComplete(() {
    _refreshFuture = null;
  });
}
```

Ese `??=` es todo el mecanismo. La primera petición que llama crea el futuro y
lo guarda; las que llaman mientras sigue en curso **reciben el mismo futuro** y
esperan su resultado. Al terminar, el campo vuelve a `null` para que la próxima
vez se renueve de nuevo.

Dos razones por las que importa:

- **No se cierra la sesión por error.** Todas obtienen el resultado real de la
  renovación, no un "ahora no puedo" que se confunda con "la sesión no sirve".
- **No hay dos renovaciones a la vez.** Usarían el mismo refresh token, y la API
  trata esa reutilización como robo: revoca la sesión completa.

### Los tres desenlaces de un 401

```text
Llega 401
  │
  ├─ ¿code == session_invalidated?          -> no se renueva. La sesion fue
  │                                            cerrada desde otro dispositivo.
  ├─ ¿es /auth/login /refresh /logout?      -> no se renueva. Evita recursion.
  ├─ ¿ya se reintento (extra['retried'])?   -> no se renueva. Evita bucle.
  │
  └─ recuperable:
        ¿el token que llevaba sigue siendo el vigente?
            no  -> otra peticion ya renovo. Reintentar con el actual.
            si  -> await _refreshSession()  (compartido)
                     exito  -> reintentar con el token nuevo
                     fallo  -> emitir evento de sesion invalida
```

La rama "otra petición ya renovó" cubre a la **rezagada**: la que salió antes de
la renovación y llegó al servidor después. Su 401 ya está resuelto, así que
reintentarla directamente evita rotar el refresh token sin necesidad.

### Ejemplo: el arranque con token vencido

```text
t=0    stories, vocabulary y progress salen con el token vencido
t=50   los tres 401 vuelven casi juntos
       stories    -> crea la renovacion
       vocabulary -> espera la misma
       progress   -> espera la misma
t=90   la renovacion responde: token nuevo guardado
       los tres se reintentan y devuelven 200
```

Una sola llamada a `/auth/refresh`, tres peticiones satisfechas, cero
interrupciones para el usuario.

---

## Qué no romper

- **No llames a `_performRefresh` directamente.** Pasa siempre por
  `_refreshSession`, que es lo único que garantiza una renovación a la vez.
- **No quites el flag `retried`.** Es lo que impide un bucle infinito si la
  petición vuelve a fallar con el token nuevo.
- **`session_invalidated` no se renueva.** Ese código significa que la sesión se
  cerró desde otro dispositivo; reintentar solo retrasaría lo inevitable.
- **Cuidado al tocar `_handleError`:** un `false` de la renovación termina en un
  evento de sesión inválida, que saca al usuario. Solo debe llegar ahí cuando la
  renovación realmente fracasó.

---

## Cómo probarlo

`ApiClient` acepta un `Dio` opcional marcado `@visibleForTesting`, lo que permite
sustituir el adaptador HTTP y simular el servidor sin red:

```dart
final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl))
  ..httpClientAdapter = miAdaptadorFalso;

final client = ApiClient(/* … */, dio: dio);
```

Las pruebas viven en
[`test/core/network/api_client_refresh_test.dart`](../test/core/network/api_client_refresh_test.dart)
y cubren los tres casos: 401 simultáneos con una sola renovación, ausencia de
cierres falsos, y la petición rezagada.

Un detalle a conservar si se amplían: el adaptador falso **retrasa la respuesta
de `/auth/refresh` a propósito**. Sin esa latencia las peticiones no llegan a
solaparse y las pruebas pasarían incluso con una implementación defectuosa.

---

## Referencias

- [`docs/guia-sesion-web-tokens.md`](guia-sesion-web-tokens.md) — dónde vive cada token y el arranque en Web.
- `.handoff/auditoria-seguridad-flutter-readeriz.md` — hallazgo FLT-SEC-007.
