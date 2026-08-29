# Guía de sesión y tokens en Readeriz Web

## Objetivo

Esta guía explica cómo Readeriz maneja los tokens de sesión y por qué lo hace
distinto en Flutter Web que en Android/iOS. Corresponde al hallazgo
**FLT-SEC-004** de la auditoría de seguridad.

Está escrita para alguien que llega nuevo a este ajuste: primero el problema,
después la solución, después el mapa de archivos, y al final cómo probarlo y qué
no romper.

---

## El problema en una frase

En Flutter Web, `flutter_secure_storage` **no guarda nada de forma segura**:
por debajo escribe en `localStorage` del navegador. Cualquier XSS —propio o de
una extensión— puede leer ese almacenamiento. Guardar ahí el refresh token
significaba que un atacante podía quedarse con una sesión renovable durante
mucho tiempo, no solo los 15 minutos que dura un access token.

En Android e iOS ese problema no existe: ahí `flutter_secure_storage` sí se
apoya en Keystore y Keychain, que son almacenes reales del sistema operativo.

Por eso la solución **no puede ser la misma en las dos plataformas**, y de ahí
sale casi toda la estructura que verás abajo.

---

## La solución en tres decisiones

### 1. El refresh token nunca llega al cliente Web

La API distingue el tipo de cliente que le habla mediante `clientType`:

| `clientType` | Quién es | Cómo recibe el refresh token |
|--------------|----------|------------------------------|
| `mobile`     | App nativa Android/iOS | En el cuerpo de la respuesta |
| `app_web`    | Readeriz compilado a Web | **No lo recibe**: cookie `HttpOnly` |
| `web`        | Panel administrativo React | **No lo recibe**: cookie `HttpOnly` |

Cuando Readeriz Web inicia sesión, la API responde **sin** el campo
`refreshToken` y en su lugar manda una cabecera `Set-Cookie` con la cookie
`er_refresh_token`, marcada `HttpOnly`. Eso significa que el navegador la
guarda y la reenvía sola, pero **JavaScript no puede leerla**: no aparece en
`document.cookie`. Un XSS ya no tiene de dónde tomarla.

### 2. El access token vive solo en memoria (en Web)

Quitar el refresh token y dejar el access token en `localStorage` habría dejado
la puerta entreabierta. En Web el access token se guarda en una variable en
memoria y **se pierde a propósito** al recargar la página.

En nativo se sigue guardando en almacenamiento seguro, porque ahí sí lo es y
evita pedir credenciales en cada arranque.

### 3. Si no se persiste nada, hay que poder recuperar la sesión

Esta es la consecuencia que suele olvidarse: al no guardar nada en Web,
**recargar la página dejaría al usuario fuera**. La cookie sigue viva, así que
al arrancar la app pregunta por un access token nuevo antes de mandar a nadie al
login.

---

## Cómo protege la cookie contra CSRF

Una cookie que el navegador envía sola tiene un efecto secundario conocido: un
sitio malicioso podría provocar una petición a la API y el navegador adjuntaría
la cookie igual. Eso es CSRF.

La defensa es el patrón de **doble envío**:

1. La API emite, junto a la cookie `HttpOnly`, una segunda cookie **legible**:
   `er_csrf_token`.
2. Al renovar sesión, la app lee esa cookie legible y **repite su valor** en la
   cabecera `X-CSRF-Token`.
3. La API compara cookie y cabecera. Si no coinciden, rechaza.

Funciona porque un sitio de terceros puede *provocar* la petición, pero no puede
*leer* la cookie del dominio de la API para copiarla en la cabecera.

---

## Recorrido de los cuatro momentos clave

### Inicio de sesión (Web)

```text
App  --POST /auth/login {clientType: "app_web", ...}-->  API
App  <--200 {accessToken, refreshToken: null}
        Set-Cookie: er_refresh_token (HttpOnly)
        Set-Cookie: er_csrf_token (legible)------------  API

SessionTokenStore guarda el access token en memoria.
El refresh token no se guarda: ya está en la cookie.
```

### Cualquier petición autenticada

```text
Interceptor de Dio (_attachToken):
  1. _attachWebCookieOptions -> withCredentials = true  (solo Web)
                             -> X-CSRF-Token, si la cookie está disponible
  2. Authorization: Bearer <access token en memoria>
```

`withCredentials` es lo que hace que el navegador incluya las cookies en una
petición hacia otro origen. Sin eso, la cookie existe pero no viaja.

### El access token expira (401)

```text
Respuesta 401
  -> _handleError decide si puede renovar
  -> _refreshSession: POST /auth/refresh
       Web:    {clientType: "app_web"}  + cookie + X-CSRF-Token
       Nativo: {clientType: "mobile", refreshToken: "..."}
  -> guarda el access token nuevo y reintenta la petición original una vez
```

La petición se reintenta marcada con `retried`, para no entrar en un bucle si
el segundo intento también falla.

### Recarga de página (solo Web)

```text
Arranque -> AuthBloc -> AuthRepositoryImpl.verifySession()

  ¿La bandera local dice que había sesión?      no -> a login
  ¿Hay access token en memoria?                 sí -> verificar contra la API
  No hay, y estamos en Web:
      -> sessionRestorer.restoreSession()
         (renueva con la cookie)
      -> ¿lo consiguió?  sí -> sesión recuperada
                         no -> limpiar y a login
```

La «bandera local» es `is_logged_in` en `SharedPreferences`. Es solo un booleano,
no un secreto: sirve para no llamar a la API cuando el usuario nunca inició
sesión.

### Cierre de sesión

`AuthRepositoryImpl.clearSession()` es el punto por el que pasan **todos** los
cierres: el botón de salir, una sesión invalidada desde otro dispositivo y una
cookie de refresco ya vencida al arrancar. Ahí se borra el token local, se baja
la bandera `is_logged_in` y se vacían las cachés de sesión.

Esas cachés son las que implementan `SessionScopedCache` —hoy solo
`StoryAssetLoader`, que guarda portadas y audio que la API entrega únicamente
con sesión activa—. Se vacían también al **iniciar** sesión, porque puede
tratarse de otra cuenta en el mismo proceso.

Si añades una caché con datos privados del usuario, impleméntala como
`SessionScopedCache` y regístrala en `sessionCaches` dentro de
`app_dependencies.dart`. Es lo único que hace falta para que se limpie sola.

---

## Mapa de archivos

### Núcleo del ajuste

| Archivo | Qué hace |
|---------|----------|
| `lib/core/auth/auth_session_transport.dart` | Decide, según la plataforma, qué `clientType` se envía y si el refresh viaja por cookie. Es el interruptor del que dependen los demás. |
| `lib/core/auth/session_token_store.dart` | Concentra **dónde vive cada token**. En Web: access en memoria, refresh en ninguna parte. En nativo: ambos en almacenamiento seguro. |
| `lib/core/auth/session_restorer.dart` | Interfaz mínima (`restoreSession()`) para recuperar la sesión sin credenciales. Existe para que la capa de datos no dependa del cliente HTTP completo y para poder sustituirla en pruebas. |
| `lib/core/auth/session_scoped_cache.dart` | Interfaz de las cachés en memoria con datos privados del usuario. La capa de auth las vacía sin conocerlas en detalle. |

### Lectura de la cookie CSRF

Dart no permite importar `dart:html` en código que también compila a nativo, así
que se usa el patrón de **importación condicional**: tres archivos, uno de
fachada y dos implementaciones.

| Archivo | Qué hace |
|---------|----------|
| `lib/core/network/csrf_token_reader.dart` | Fachada. Elige la implementación según la plataforma de compilación. |
| `lib/core/network/csrf_token_reader_web.dart` | Lee `document.cookie` con el paquete `web`. |
| `lib/core/network/csrf_token_reader_stub.dart` | Devuelve `null`. En nativo no hay cookies de navegador. |

### Integración

| Archivo | Qué cambió |
|---------|-----------|
| `lib/core/network/api_client.dart` | Implementa `SessionRestorer`. Añade `withCredentials` y `X-CSRF-Token` en Web, usa `SessionTokenStore` en vez del storage directo, y renueva con cookie o con token del cuerpo según la plataforma. |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | Envía el `clientType` correcto, ya no persiste tokens por su cuenta, y recupera la sesión con la cookie al arrancar en Web. |
| `lib/app/di/app_dependencies.dart` | Crea el `SessionTokenStore` y lo comparte entre el cliente HTTP y el repositorio. Le pasa el `ApiClient` como `sessionRestorer` y la lista de `sessionCaches`. |
| `lib/core/media/story_asset_loader.dart` | Implementa `SessionScopedCache`: sus portadas y audio se vacían en cada cambio de sesión. |
| `lib/app/config/app_config.dart` | Expone `csrfCookieName`, configurable por `--dart-define=CSRF_COOKIE_NAME`. |

### Pruebas

| Archivo | Qué cubre |
|---------|-----------|
| `test/core/auth/auth_session_transport_test.dart` | Que Web use `app_web` y nativo use `mobile`. |
| `test/features/auth/auth_repository_impl_test.dart` | Que en Web no quede ningún token en disco, que el logout no mande el refresh por el cuerpo, y que la sesión se recupere —o se cierre— tras recargar. |
| `test/core/media/story_asset_loader_test.dart` | Que vaciar la caché obligue a volver a descargar el recurso. |
| `e2e/readeriz_web_session_security.spec.mjs` | La verificación real, con navegador y API de verdad. |

---

## Diferencias por plataforma, de un vistazo

| | Flutter Web | Android / iOS |
|---|---|---|
| `clientType` | `app_web` | `mobile` |
| Refresh token | Cookie `HttpOnly` (la app nunca lo ve) | Almacenamiento seguro |
| Access token | Memoria del proceso | Almacenamiento seguro |
| CSRF | Cookie legible repetida en `X-CSRF-Token` | No aplica |
| Al recargar/reabrir | Renueva con la cookie | Lee el token del almacenamiento |
| Cookies en las peticiones | `withCredentials: true` | No aplica |

---

## Configuración necesaria

### En la app

```bash
flutter build web \
  --dart-define=API_BASE_URL=https://api.tudominio.com/api/v1 \
  --dart-define=APP_ENV=production \
  --dart-define=CSRF_COOKIE_NAME=er_csrf_token
```

`CSRF_COOKIE_NAME` solo hace falta si la API cambia el nombre por defecto. Debe
coincidir con `CSRF_COOKIE_NAME` del `.env` de la API.

### En la API (`english_reader_api/.env`)

```bash
REFRESH_COOKIE_NAME=er_refresh_token
CSRF_COOKIE_NAME=er_csrf_token
COOKIE_SECURE=true          # false solo en desarrollo sobre http://localhost
COOKIE_SAME_SITE=none       # lax si app y API comparten dominio
CORS_ORIGINS=...            # debe incluir el origen exacto de Readeriz Web
```

Tres detalles que cuestan tiempo si se pasan por alto:

- **`CORS_ORIGINS` debe listar el origen de la app.** Si falta, el navegador
  bloquea la respuesta y el error que se ve es «no se pudo conectar con el
  servidor», idéntico a tener la API caída.
- **`COOKIE_SECURE=true` exige HTTPS.** Sobre `http://localhost` el navegador
  descarta la cookie y el login parece funcionar pero la sesión no sobrevive.
- **`SameSite`**: `lax` basta si app y API comparten dominio registrable
  (`app.midominio.com` y `api.midominio.com`). Si están en dominios distintos,
  hace falta `none` **con** `Secure`.

---

## Cómo verificarlo

### Pruebas automáticas

```bash
flutter analyze
flutter test
npm run e2e:web          # levanta API + build Web y corre Playwright
```

La prueba E2E de este ajuste comprueba cuatro cosas contra la API real:

1. El login `app_web` **no** devuelve `refreshToken` en el cuerpo.
2. La cookie de refresco existe, es `HttpOnly` y **no** aparece en
   `document.cookie`.
3. Ni `localStorage` ni `sessionStorage` contienen claves con «token» ni valores
   con forma de JWT. La segunda comprobación es deliberada: detecta un token
   guardado bajo un nombre distinto.
4. Tras recargar, `/auth/refresh` responde 200 y la app vuelve a mostrar las
   historias.

### A mano, en el navegador

1. Inicia sesión en Readeriz Web.
2. DevTools → **Application → Cookies**: `er_refresh_token` debe aparecer con la
   casilla `HttpOnly` marcada.
3. DevTools → **Application → Local Storage**: no debe haber ninguna clave con
   un token.
4. En la consola, `document.cookie` no debe mostrar `er_refresh_token`.
5. Recarga con F5: debes seguir dentro, y en **Network** verás un
   `POST /auth/refresh` con respuesta 200.

---

## Qué no romper

- **No guardes tokens con `SecureStorageService` directamente.** Usa siempre
  `SessionTokenStore`; es lo que sabe qué hacer en cada plataforma.
- **No asumas que hay refresh token en Web.** `readRefreshToken()` devuelve
  `null` ahí por diseño; no es un error ni una sesión rota.
- **No quites `withCredentials`.** Sin él la cookie existe pero no viaja, y el
  refresco falla sin mensaje claro.
- **No rodees el `ApiClient` con un `Dio` o un `http` propio.** El interceptor es
  quien añade `withCredentials`, la cabecera CSRF y el `Authorization`; una
  petición hecha por fuera sale sin nada de eso y falla de formas confusas.
- **No cambies el `clientType` a mano.** Sale de `AuthSessionTransport`, y la API
  decide con él si emite cookie o devuelve el token en el cuerpo.

---

## Lo que este ajuste no cubre

- **CSP y cabeceras de seguridad en el hosting Web** (hallazgo FLT-SEC-008,
  abierto). La cookie `HttpOnly` limita el daño de un XSS, pero una CSP estricta
  es lo que reduce la probabilidad de que ocurra. Son complementarios.
- **Serialización del refresco ante varios 401 simultáneos** (FLT-SEC-007,
  abierto). Hoy `_refreshSession()` usa una bandera booleana: si ya hay un
  refresco en curso, la segunda petición recibe `false` en vez de esperar el
  mismo resultado.

---

## Referencias

- `docs/guia-despliegue-web-y-csp.md` — la CSP que gobierna `connect-src`, y por qué las tipografías van empaquetadas.
- `docs/guia-renovacion-de-sesion.md` — cómo se recupera un 401 y por qué la renovación es una sola aunque fallen varias peticiones.
- `docs/guia-cache-de-recursos-privados.md` — cómo funciona la caché de portadas y audio, y cómo registrar una nueva.
- `.handoff/auditoria-seguridad-flutter-readeriz.md` — hallazgo original y estado.
- `docs/planning/08-sesion-seguridad-dispositivo.md` — política de sesión y almacenamiento.
- `docs/planning/03-integracion-api-flutter.md` — contrato con la API.
