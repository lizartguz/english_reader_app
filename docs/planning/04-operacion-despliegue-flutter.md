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

No se deben hardcodear URLs de producción en el código.

## Builds conceptuales

Android:

```bash
flutter build apk
flutter build appbundle
```

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
