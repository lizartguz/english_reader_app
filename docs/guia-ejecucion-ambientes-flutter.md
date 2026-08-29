# Guía de ejecución por ambientes Flutter - Readeriz

## Objetivo

Esta guía explica cómo ejecutar o compilar Readeriz usando valores por ambiente.
Sirve para recordar qué comando usar en desarrollo, staging y producción.

## Idea principal

Flutter permite pasar valores al momento de ejecutar o compilar la app con:

```text
--dart-define=NOMBRE=VALOR
```

El código no guarda la URL fija en un archivo. El build recibe el valor y lo
usa para esa versión de la app.

Ejemplo:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.readeriz.com/api/v1 --dart-define=APP_ENV=production
```

Ese comando le dice a la app:

```text
API_BASE_URL=https://api.readeriz.com/api/v1
APP_ENV=production
```

## Variables actuales

| Variable | Para qué sirve | Ejemplo |
|---|---|---|
| `API_BASE_URL` | Define la URL de la API que consume la app. | `https://api.readeriz.com/api/v1` |
| `APP_ENV` | Define el ambiente de ejecución. | `development`, `staging`, `production` |
| `APP_VERSION` | Define una versión visible o trazable de la app si se necesita. | `1.0.0` |
| `CSRF_COOKIE_NAME` | Define la cookie CSRF legible usada por Flutter Web. | `er_csrf_token` |

## Desarrollo local

Para desarrollo normal se puede ejecutar:

```powershell
flutter run
```

Cuando no se pasa `APP_ENV`, la app usa:

```text
APP_ENV=development
```

En Web o escritorio usa por defecto:

```text
http://localhost:3000/api/v1
```

En Android emulator usa por defecto:

```text
http://10.0.2.2:3000/api/v1
```

En Android, el HTTP claro queda permitido solo para variantes `debug` y
`profile`, limitado a hosts locales (`localhost`, `127.0.0.1` y `10.0.2.2`). En
`release`, Android usa una configuración de red que bloquea HTTP y exige que la
API productiva sea HTTPS.

## Desarrollo explícito en Web

```powershell
flutter run -d chrome --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

## Desarrollo explícito en Android emulator

```powershell
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

## Staging

Staging debe usar una API real con HTTPS. No debe usar `localhost`.

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://staging-api.readeriz.com/api/v1 --dart-define=APP_ENV=staging
```

Para Web:

```powershell
flutter build web --no-web-resources-cdn --dart-define=API_BASE_URL=https://staging-api.readeriz.com/api/v1 --dart-define=APP_ENV=staging
```

## Producción

Producción debe usar la API oficial con HTTPS.

APK:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.readeriz.com/api/v1 --dart-define=APP_ENV=production
```

App Bundle para Play Store:

```powershell
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.readeriz.com/api/v1 --dart-define=APP_ENV=production
```

Web:

```powershell
flutter build web --no-web-resources-cdn --dart-define=API_BASE_URL=https://api.readeriz.com/api/v1 --dart-define=APP_ENV=production
```

## Reglas de seguridad

En `development`, la app permite URLs locales.

En Android, esa excepción de HTTP local solo existe en `debug` y `profile`.
`release` no acepta tráfico HTTP claro aunque alguien pase una URL `http://`;
además, `APP_ENV=staging` y `APP_ENV=production` ya rechazan URLs no HTTPS al
arrancar.

En `staging` y `production`, la app exige:

- `API_BASE_URL` obligatoria.
- URL con `https://`.
- No usar `localhost`.
- No usar `127.0.0.1`.
- No usar `10.0.2.2`.
- No usar `0.0.0.0`.

Si una regla no se cumple, la app falla temprano para evitar publicar una build
mal configurada.

## Qué sí pasar por dart-define

- URLs públicas de API.
- Nombre de ambiente.
- Flags simples de configuración.
- Versiones visibles.
- Nombres públicos de cookies o cabeceras.

## Qué no pasar por dart-define

No se deben pasar secretos reales porque una app móvil o Web compilada puede ser
inspeccionada.

No usar `--dart-define` para:

- Passwords.
- Tokens privados.
- Llaves secretas de proveedores.
- Credenciales de base de datos.

## Recordatorio rápido

Desarrollo:

```powershell
flutter run
```

Producción Android:

```powershell
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.readeriz.com/api/v1 --dart-define=APP_ENV=production
```

Producción Web:

```powershell
flutter build web --no-web-resources-cdn --dart-define=API_BASE_URL=https://api.readeriz.com/api/v1 --dart-define=APP_ENV=production
```
