# Readeriz

Aplicacion Flutter para usuarios cliente de Readeriz.

## Estado implementado

- Configuracion por ambiente con `API_BASE_URL`, `APP_ENV` y `APP_VERSION`.
- Nombre de app centralizado en `AppInfo.displayName` y logo base en `assets/images/logo/logo.png`.
- Cliente HTTP con Dio, envoltura `{ success, message, data, meta }`, bearer token y refresh token.
- Sesion movil con `device_id`, `clientType: mobile`, almacenamiento seguro y verificacion inicial.
- Manejo global de sesion expirada o invalidada con retorno a login.
- Navegacion con `go_router` y rutas protegidas.
- Doble back para salir en Android desde la pantalla principal.
- Login, listado de historias, lector, consulta de palabra, guardado en vocabulario y progreso por scroll.
- Pronunciación de palabras con audio remoto de la API y fallback TTS local.
- Etiquetas semánticas base para lector, historias y pronunciación.
- Preferencias locales del lector para tamaño de texto e interlineado persistidas con `shared_preferences`.
- Responsividad base para móvil, tablet y Web con historias en lista/grid y contenido centrado en pantallas amplias.
- Listado, cambio de estado, notas y eliminacion de vocabulario personal.
- Keys estables para pruebas de login, historias, lector y vocabulario.

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

## Validacion

```bash
dart format lib
flutter analyze
flutter test
flutter build web --dart-define=API_BASE_URL=http://localhost:3000/api/v1 --dart-define=APP_ENV=development
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1 --dart-define=APP_ENV=development
```
