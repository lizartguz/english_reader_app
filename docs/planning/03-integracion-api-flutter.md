# Integración API Flutter - English Reader

## Objetivo

Este documento define cómo `english_reader_app` consume `english_reader_api`.

## API base

La URL base debe configurarse por ambiente.

Configuración esperada:

```text
API_BASE_URL
APP_ENV
```

`APP_ENV=development` puede usar la URL local por defecto. Los ambientes
`staging` y `production` deben recibir `API_BASE_URL` de forma explícita,
siempre con HTTPS y sin hosts locales.

## Autenticación

Flutter debe autenticarse contra la API.

Flujo:

```text
usuario inicia sesión
  -> API devuelve sesión
  -> Flutter guarda tokens de forma segura
  -> Flutter consume rutas protegidas
  -> Flutter renueva sesión cuando corresponda
```

Para móvil, el access token y el refresh token deben guardarse en
almacenamiento seguro del dispositivo usando `clientType: mobile`.

Para Flutter Web, la app debe enviar `clientType: app_web`: el access token se
mantiene del lado Flutter y el refresh token viaja en cookie `HttpOnly` emitida
por la API. Flutter Web no debe persistir el refresh token.

`shared_preferences` no debe almacenar tokens sensibles. Debe usarse para flags y preferencias no sensibles, como recordar que existe sesión local, tema visual o datos mínimos de UI.

Los tokens deben guardarse con almacenamiento seguro cuando la plataforma lo permita.

Cuando Flutter Web renueva sesión, debe enviar cookies del navegador y repetir
la cookie CSRF legible en la cabecera `X-CSRF-Token`.

En recuperación de contraseña Web, la ruta pública `/reset-password` puede
recibir `?token=...` desde el correo. La app debe leer ese token una sola vez y
limpiar la URL visible con `history.replaceState` para que no permanezca en la
barra ni en la entrada actual del historial del navegador.

## Dispositivo único por usuario

La app debe enviar un identificador de dispositivo al iniciar sesión.

Flujo conceptual:

```text
Flutter obtiene o crea device_id
  -> guarda device_id en almacenamiento seguro
  -> login envía credenciales + device_id + plataforma + versión
  -> API crea sesión activa para ese dispositivo
  -> API invalida sesiones previas del mismo usuario CLIENT
```

Si la misma cuenta inicia sesión en otro dispositivo, la sesión anterior debe dejar de ser válida.

Cuando Flutter reciba una respuesta de sesión invalidada, debe:

- limpiar sesión local
- mostrar mensaje amigable
- redirigir al login

Mensaje sugerido:

```text
Tu sesión fue cerrada porque se inició en otro dispositivo.
```

## Endpoints esperados

Flutter consumirá endpoints para:

- login
- refresh token
- listar historias
- detalle de historia
- consulta de palabra
- guardar palabra
- listar vocabulario
- actualizar vocabulario
- eliminar vocabulario
- actualizar progreso
- obtener archivos autorizados

## Implementación vigente en Flutter

El cliente HTTP central usa `dio` y consume la envoltura estándar
`{ success, message, data, meta }`.

Reglas vigentes:

- `accessToken`, `refreshToken` y `device_id` viven en almacenamiento seguro.
- `shared_preferences` conserva solo el flag no sensible `is_logged_in`.
- cada request protegida adjunta `Authorization: Bearer <token>`.
- si una respuesta protegida devuelve 401, la app intenta renovar sesión salvo
  en endpoints propios de autenticación.
- si la sesión fue invalidada o ya no puede renovarse, la app emite un evento
  global, limpia sesión local y redirige a login con mensaje amigable.

## Manejo de errores

La app debe mostrar mensajes amigables.

No debe mostrar errores técnicos del backend.

La API debe enviar respuestas controladas con mensajes amigables cuando el error
provenga del backend o de reglas de negocio.

Flutter debe encargarse de traducir a mensajes amigables los fallos propios de
la app o del dispositivo, por ejemplo:

- sin conexión a internet
- timeout
- respuesta inválida o incompleta
- sesión local dañada
- archivo no disponible en el dispositivo
- error de reproducción de audio local

Regla:

```text
Error de API controlado
  -> mostrar mensaje amigable recibido desde la API

Error local de Flutter, red o dispositivo
  -> mostrar mensaje amigable definido en Flutter
```

La implementación vigente centraliza esta traducción en `mapDioException()`.
El mapper interpreta fallos de transporte, cancelaciones, 401, 403, 404, 409,
422, 429 y 5xx. Los códigos estables de la API tienen prioridad sobre textos
variables; los errores 5xx usan el fallback local para no exponer detalles
técnicos.

Si la API devuelve un error técnico inesperado, Flutter no debe mostrarlo al
usuario. Debe usar un mensaje genérico y, cuando corresponda, enviar el contexto
necesario a los logs del backend o al mecanismo de monitoreo definido.

Ejemplos:

```text
No se pudo cargar la historia. Inténtalo nuevamente.
No se pudo consultar la palabra.
Tu sesión ha expirado. Inicia sesión nuevamente.
```

Si la API está caída o no responde, Flutter debe mostrar un mensaje amigable sin detalles técnicos:

```text
No se pudo conectar con el servidor. Inténtalo nuevamente en unos minutos.
```

Si el usuario intenta acceder a una función no autorizada, debe mostrarse un mensaje claro:

```text
No tienes permiso para realizar esta acción.
```

## Verificación real con API local

El proyecto incluye `tool/verify_real_api_flow.dart` para validar el contrato
real sin escribir tokens en disco.

Flujo validado:

```text
login cliente
  -> GET /app/stories
  -> GET /app/words/lookup
  -> POST /app/vocabulary
```

Comando local:

```bash
dart run tool/verify_real_api_flow.dart
```

Parámetros opcionales:

```bash
dart run tool/verify_real_api_flow.dart \
  --base-url=http://localhost:3000/api/v1 \
  --email=cliente.flutter.test@englishreader.local \
  --password=Cliente123* \
  --word=hello
```

## Archivos protegidos

Imágenes y audios deben solicitarse mediante endpoints protegidos o URLs temporales entregadas por la API.

Flutter no debe depender de rutas internas del servidor.

Regla principal:

```text
Los archivos cargados desde administración no serán públicos por defecto.
```

Solo pueden ser públicos los assets estáticos de la aplicación que no pertenezcan
al contenido administrado, por ejemplo:

- logotipo
- iconos
- imágenes decorativas propias de la app

Las imágenes y audios relacionados con historias, pronunciaciones o contenido
administrado deben estar protegidos.

Estrategias aceptadas:

```text
Opción A: endpoint autenticado
  -> Flutter solicita el archivo a la API
  -> API valida token, usuario, permisos y estado del recurso
  -> API entrega el archivo o stream

Opción B: URL temporal firmada
  -> Flutter solicita acceso a la API
  -> API valida token, usuario, permisos y estado del recurso
  -> API genera una URL temporal de corta duración
  -> Flutter usa esa URL solo para renderizar o reproducir el archivo
```

La opción B puede ser útil para Flutter Web y para componentes que necesiten una
URL directa para mostrar imágenes o reproducir audio, pero esa URL no debe ser
permanente ni pública en sentido abierto.

Requisitos:

- las URLs temporales deben expirar
- la API debe validar que el usuario pueda acceder al recurso
- no se deben exponer rutas internas del servidor
- no se deben guardar URLs temporales como datos permanentes
- si una URL expira, Flutter debe solicitar una nueva a la API
- los errores deben mostrarse con mensajes amigables

## Sin proveedores externos directos

Flutter no debe consultar directamente proveedores de diccionario o traducción.

Debe consultar la API para:

- definición
- traducción
- fonética
- ejemplos
- audio remoto

El único plugin externo aprobado para reproducción local de texto a voz en Flutter es:

```text
flutter_tts
```

## Impacto cruzado

Si cambia la API, deben revisarse:

- modelos Dart
- datasources
- repositories
- use cases
- pantallas
- mensajes de error
- almacenamiento de tokens

## Criterios de cierre de este documento

Este documento se considera suficiente cuando define:

- API base por ambiente
- autenticación
- endpoints esperados
- errores amigables
- archivos protegidos
- prohibición de proveedores externos directos
- impacto cruzado
