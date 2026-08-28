# Librerías y dependencias Flutter - English Reader App

## Objetivo

Este documento define plugins y paquetes recomendados para `english_reader_app`.

La selección toma como referencia `D:\projects\dentasync_app`, pero se adapta al alcance real de English Reader.

## Paquetes base aprobados o recomendados

| Uso | Paquete | Estado |
| --- | --- | --- |
| Estado BLoC | `flutter_bloc` | Aprobado |
| Comparación de estados | `equatable` | Aprobado |
| Inyección/estado simple | `provider` | Aprobado |
| Preferencias no sensibles | `shared_preferences` | Aprobado |
| Tokens y device id | `flutter_secure_storage` `10.3.1` | Aprobado por seguridad y build Android |
| Navegación | `go_router` | Recomendado |
| Cliente HTTP | `dio` | Recomendado |
| Texto a voz | `flutter_tts` | Aprobado |
| Audio remoto | `audioplayers` | Aprobado |
| Imágenes con caché | `cached_network_image` | Recomendado |
| Internacionalización/formato | `intl` | Recomendado |
| Pruebas | `flutter_test` | Base |
| Lints | `flutter_lints` | Recomendado |
| Launcher icons | `flutter_launcher_icons` | Aprobado |
| E2E Web | `@playwright/test` | Aprobado |
| Servidor estático E2E | `http-server` | Aprobado |
| Verificación visual E2E | `pngjs` | Aprobado |

## Referencia tomada de DentaSync

La app de referencia usa paquetes útiles como:

```text
flutter_bloc
equatable
shared_preferences
flutter_secure_storage
go_router
cached_network_image
intl
permission_handler
```

Para English Reader se rescatan principalmente los relacionados con estado, sesión, navegación, almacenamiento seguro e imágenes.

## BLoC

`flutter_bloc` será el patrón principal para manejar estado de funcionalidades.

Uso:

- autenticación
- listado de historias
- lector
- consulta de palabra
- vocabulario
- progreso

Referencia: https://pub.dev/packages/flutter_bloc

## Provider

`provider` se usará para dependencias y estado simple de alcance global.

Uso:

- servicios compartidos
- configuración de entorno
- tema si se decide manejarlo simple
- preferencias locales

No debe duplicar estado que pertenezca a BLoC.

Referencia: https://pub.dev/packages/provider

## SharedPreferences

`shared_preferences` se usará solo para datos no sensibles.

Uso permitido:

- flag de sesión local
- preferencias de tema
- preferencias de lectura
- último nivel consultado
- datos de UI no sensibles

No debe guardar:

- access token
- refresh token
- contraseñas
- secretos

Referencia: https://pub.dev/packages/shared_preferences

## Flutter Secure Storage

`flutter_secure_storage` se recomienda para datos sensibles.

Uso:

- access token
- refresh token en móvil
- device id
- datos mínimos de sesión sensibles

En Flutter Web el refresh token no se persiste con `flutter_secure_storage`: se
recibe como cookie `HttpOnly` desde la API y se acompaña con CSRF.

La versión Android vigente queda fijada en `10.3.1` porque compila contra SDK
36 y mantiene la implementación segura de la rama 10.x. La versión 11.x exige
`compileSdk = 37`, pero el SDK local disponible expone la plataforma como
`android-37.0`, lo que bloquea `assembleDebug` en este entorno. Cualquier salto
a 11.x debe validarse con un SDK Android que entregue `platforms;android-37`.

Referencia: https://pub.dev/packages/flutter_secure_storage

## Go Router

`go_router` se recomienda para navegación declarativa, rutas protegidas y soporte web.

Referencia: https://pub.dev/packages/go_router

## Dio

`dio` se recomienda como cliente HTTP por sus interceptores.

Uso:

- adjuntar token
- manejar refresh token
- detectar sesión expirada
- mapear errores amigables
- timeout y cancelación

Referencia: https://pub.dev/packages/dio

## Flutter TTS

`flutter_tts` se usará para texto a voz cuando no exista audio remoto o cuando se necesite pronunciar una palabra/texto.

Referencia: https://pub.dev/packages/flutter_tts

## Audioplayers

`audioplayers` reproduce URLs de pronunciación entregadas por la API en Android,
iOS y Web. Si falla la URL, el flujo usa `flutter_tts` como respaldo local.

Referencia: https://pub.dev/packages/audioplayers

## Flutter Launcher Icons

`flutter_launcher_icons` se usa como herramienta de desarrollo para generar
íconos Android, iOS y Web desde `assets/images/logo/logo.png`.

Comando vigente:

```bash
dart run flutter_launcher_icons
```

Referencia: https://pub.dev/packages/flutter_launcher_icons

## Playwright Web E2E

`@playwright/test` se usa fuera de Flutter para abrir Chrome contra la build Web
real. La configuración compila `flutter build web --no-web-resources-cdn`,
levanta `http-server` en `localhost:53633` y valida escritorio más viewport
móvil.

`pngjs` inspecciona capturas para evitar falsos positivos cuando el canvas queda
blanco. La API se levanta desde el proyecto `english_reader_api` y se reutiliza
si ya responde en `http://localhost:3000/api/v1/health`.

Comandos:

```bash
npm install
npx playwright install chrome
npm run e2e:web
```

## Cached Network Image

`cached_network_image` se puede usar para optimizar carga visual de imágenes autorizadas.

Debe respetar archivos protegidos y headers de autenticación cuando corresponda.

## Decisiones cerradas

- `dio` queda como cliente HTTP por interceptores, refresh token y mapeo de errores.
- `cached_network_image` queda aprobado para imágenes con URL autorizada por API.
- `provider` se usa para inyección de dependencias y servicios compartidos; BLoC conserva el estado de flujos.
- Los smoke tests de flujo usan `flutter_test` con rutas y widgets reales.

## Criterios de cierre

Este documento se considera suficiente cuando define:

- paquetes base
- uso de BLoC
- uso de Provider
- uso seguro de almacenamiento
- navegación
- cliente HTTP
- TTS
- imágenes
- decisiones de dependencias
