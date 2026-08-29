# Readeriz

Aplicacion Flutter para usuarios cliente de Readeriz.

## Estado implementado

- Configuracion por ambiente con `API_BASE_URL`, `APP_ENV` y `APP_VERSION`.
- Nombre de app centralizado en `AppInfo.displayName` y logo base en `assets/images/logo/logo.png`.
- Cliente HTTP con Dio, envoltura `{ success, message, data, meta }`, bearer token y refresh token por transporte.
- Normalizacion de errores por red, sesion, permisos, no encontrado, conflicto, validacion, rate limit y fallos 5xx.
- Sesion movil con `clientType: mobile`, refresh token en almacenamiento seguro y verificacion inicial.
- Sesion Flutter Web con `clientType: app_web`, refresh token en cookie HttpOnly y CSRF por cookie legible.
- Reset password Web limpia `?token=` de la URL tras leerlo para evitar exposicion en la barra o historial.
- Manejo global de sesion expirada o invalidada con retorno a login.
- Navegacion con `go_router` y rutas protegidas.
- Doble back para salir en Android desde la pantalla principal.
- Login, listado de historias, lector, consulta de palabra, guardado en vocabulario y progreso por scroll.
- Pronunciación de palabras con audio remoto de la API y fallback TTS local.
- Etiquetas semánticas base para lector, historias, progreso, pronunciación y vocabulario.
- Activacion de palabras del lector con teclado en Web/escritorio.
- Preferencias locales del lector para tamaño de texto e interlineado persistidas con `shared_preferences`.
- Responsividad base para móvil, tablet y Web con historias en lista/grid y contenido centrado en pantallas amplias.
- Listado, cambio de estado, notas y eliminacion de vocabulario personal.
- Keys estables para pruebas de login, historias, lector y vocabulario.
- Smoke test de flujo para login, lector, lookup y vocabulario con rutas reales.
- Verificador real de API para login, historias, lookup y vocabulario contra backend local.
- Registro de cuenta cliente, recuperación de contraseña y definición de contraseña nueva con token.
- Búsqueda local de historias y vocabulario, incluyendo nivel, género, traducción, notas y estado.
- Estados vacíos y de error con título, icono y acción de recuperación en historias, lector y vocabulario.
- Progreso de lectura visible en cada tarjeta de historia usando `GET /app/reading-progress`.
- Narración de la historia con reproducir, pausar y barra de avance cuando la API publica audio.
- Recursos protegidos (portada y audio) descargados con la sesión activa desde `StoryAssetLoader`.
- Marca Readeriz en splash, barra de historias, formularios de cuenta y perfil.
- Splash HTML de carga en `web/index.html` para evitar lienzo en blanco al abrir la Web.
- Pruebas E2E Web reales con Playwright sobre la app renderizada (escritorio y viewport móvil).

## API local

Por defecto la app usa:

```text
http://localhost:3000/api/v1
```

En Android emulator usa automaticamente:

```text
http://10.0.2.2:3000/api/v1
```

Tambien puede configurarse al compilar o ejecutar:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:3000/api/v1 \
  --dart-define=APP_ENV=development
```

Para `staging` y `production`, `API_BASE_URL` es obligatorio, debe usar HTTPS y
no puede apuntar a hosts locales:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.readeriz.com/api/v1 \
  --dart-define=APP_ENV=production
```

Guía completa de comandos por ambiente:
[`docs/guia-ejecucion-ambientes-flutter.md`](docs/guia-ejecucion-ambientes-flutter.md).

## Validacion

```bash
dart format lib
flutter analyze
flutter test
flutter test test/flows/app_smoke_test.dart
dart run tool/verify_real_api_flow.dart
npm run e2e:web
flutter build web --dart-define=API_BASE_URL=http://localhost:3000/api/v1 --dart-define=APP_ENV=development
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1 --dart-define=APP_ENV=development
```

## Pruebas E2E Web

Validan la app Web renderizada contra la API real: login, búsqueda y filtros de
historias, lector, modal de palabra, guardado y filtros de vocabulario.

```bash
npm install
npx playwright install chrome
npm run e2e:web
npm run e2e:web:report
```

Cada corrida compila `flutter build web` y levanta su propio servidor estático,
por eso `reuseExistingServer` está en `false` para el servidor Web: así nunca se
valida un bundle viejo. La API se reutiliza si ya está corriendo en el puerto
3000.

Credenciales y URL se pueden ajustar por variables de entorno:
`E2E_CLIENT_EMAIL`, `E2E_CLIENT_PASSWORD`, `E2E_ADMIN_EMAIL`,
`E2E_ADMIN_PASSWORD`, `API_BASE_URL` y `E2E_WEB_PORT`.
