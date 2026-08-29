# Operación y despliegue Flutter - English Reader

## Objetivo

Este documento define criterios de operación y despliegue para `english_reader_app`.

## Plataformas

Plataformas objetivo:

```text
Android
iOS
Web
```

## Ambientes

Ambientes esperados:

```text
development
staging
production
```

Cada ambiente debe apuntar a su API correspondiente.

## Configuración

La app debe poder configurar:

```text
API_BASE_URL
APP_ENV
```

Reglas vigentes:

- `development` puede usar URLs locales por defecto para Web, Android emulator y escritorio.
- `staging` y `production` requieren `API_BASE_URL` explícita por `--dart-define`.
- `staging` y `production` requieren HTTPS.
- `staging` y `production` rechazan hosts locales como `localhost`, `127.0.0.1`, `0.0.0.0`, `::1` y `10.0.2.2`.

Política Android de HTTP claro:

- `main/release` usa `@xml/network_security_config` y bloquea `cleartext`.
- `debug` y `profile` reemplazan esa política por
  `@xml/dev_network_security_config`.
- la configuración de desarrollo solo permite HTTP hacia `localhost`,
  `127.0.0.1` y `10.0.2.2`.

Ejemplo productivo:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.readeriz.com/api/v1 --dart-define=APP_ENV=production
```

No se deben hardcodear URLs de producción en el código.

## Builds conceptuales

Android:

```bash
flutter build apk
flutter build appbundle
```

## Firma Android release

La variante `release` de Android debe firmarse con una llave real del proyecto.
No se permite firmar `release` con la llave debug.

El archivo local de credenciales debe llamarse:

```text
android/key.properties
```

Ese archivo no debe versionarse. La plantilla versionada queda en:

```text
android/key.properties.example
```

Contenido esperado:

```properties
storeFile=../upload-keystore.jks
storePassword=REEMPLAZAR_CON_PASSWORD_DEL_KEYSTORE
keyAlias=readeriz
keyPassword=REEMPLAZAR_CON_PASSWORD_DE_LA_LLAVE
```

La ruta `storeFile=../upload-keystore.jks` apunta a:

```text
android/upload-keystore.jks
```

Para generar una llave local de release se puede usar:

```bash
keytool -genkey -v -keystore android/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias readeriz
```

Gradle valida la presencia de `storeFile`, `storePassword`, `keyAlias` y
`keyPassword`, ademas de la existencia fisica del `.jks`, antes de compilar
`assembleRelease`, `bundleRelease` o tareas release equivalentes. Las builds
debug no requieren este archivo.

## Permisos Android

El manifest principal declara `android.permission.INTERNET` porque Readeriz
consume la API en debug, profile y release. La variante release debe conservar
este permiso para login, historias, lector, audio, vocabulario y sincronizacion
de progreso.

iOS:

```bash
flutter build ios
```

Web:

```bash
flutter build web
```

Los comandos finales pueden variar según firma, ambiente y configuración.

## Docker Engine para Flutter Web

Cuando se despliegue la versión web, puede publicarse como build estático dentro de un contenedor servido por un servidor web ligero.

Recomendaciones:

- compilar `flutter build web` fuera o dentro de etapa de build
- servir el resultado estático desde contenedor
- configurar la URL de API por ambiente
- no incluir secretos dentro del build
- coordinar CORS con `english_reader_api`

Android e iOS no se despliegan como contenedores; se distribuyen mediante sus canales correspondientes.

## Seguridad de tokens

En móvil, los tokens deben guardarse usando almacenamiento seguro.

En Web, la estrategia debe definirse con cuidado por las limitaciones del navegador.

## Recursos protegidos

La app debe consumir imágenes y audios mediante API protegida o URLs temporales autorizadas.

No debe usar rutas internas del servidor.

## Impacto por cambios de API

Cada cambio de endpoint, respuesta o autenticación en `english_reader_api` puede requerir ajustes en Flutter.

## Criterios de cierre de este documento

Este documento se considera suficiente cuando define:

- plataformas objetivo
- ambientes
- configuración
- builds conceptuales
- Docker Engine para Flutter Web
- seguridad de tokens
- recursos protegidos
- impacto de cambios API
