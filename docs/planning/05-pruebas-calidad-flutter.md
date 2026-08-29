# Pruebas y calidad Flutter - English Reader

## Objetivo

Este documento define pruebas de calidad para `english_reader_app`.

## Tipos de pruebas

La estrategia debe incluir:

```text
unit tests
widget tests
flow smoke tests
e2e tests para Flutter Web
```

El smoke test de flujo vigente usa rutas, BLoC y widgets reales con
repositorios fake para validar el flujo principal sin depender de red. Cuando la
API local esté disponible, se puede complementar con un smoke real usando los
endpoints de `english_reader_api`.

## Pruebas unitarias

Prioridad:

- casos de uso
- repositories
- normalización local auxiliar
- manejo de errores
- modelos Dart
- estados de lectura

Pruebas iniciales implementadas:

- `test/features/vocabulary/vocabulary_bloc_test.dart`
  valida carga exitosa y cambio de estado de aprendizaje con repositorio fake.
- `test/core/network/api_client_error_test.dart`
  valida traducción amigable de errores de red, sesión, permisos, 404, rate
  limit y 5xx.
- `test/core/network/api_payload_test.dart`
  valida que respuestas mal formadas de API se conviertan en `AppException`
  controlado con codigo `invalid_payload`, sin exponer errores tecnicos.
- `test/features/reader/reader_bloc_test.dart`
  valida carga de historia, restauración de progreso y sincronización silenciosa.
- `test/features/reader/reader_settings_cubit_test.dart`
  valida carga, límites, guardado y restablecimiento de preferencias del lector.
- `test/features/reader/word_detail_test.dart`
  valida la selección del primer audio remoto válido para pronunciación.
- `test/features/stories/stories_page_test.dart`
  valida que historias use lista en móvil y grid en tablet/Web.

## Smoke tests de flujo

Pruebas implementadas:

- `test/flows/app_smoke_test.dart`
  valida login, listado de historias, apertura de lector, lookup de palabra,
  guardado en vocabulario y navegación al listado de vocabulario usando el
  árbol real de la app con repositorios fake.

## Widget tests

Prioridad:

- lista de historias
- vista de lectura
- modal de palabra
- botones de reproducción
- estados de carga
- estados vacíos
- mensajes de error

Pruebas de widget implementadas:

- `test/features/auth/login_page_test.dart`
  valida que el formulario envíe credenciales al `AuthBloc`.
- `test/features/reader/widgets/reader_content_test.dart`
  valida que el lector detecte la palabra tocada sin puntuación y aplique
  tamaño/interlineado configurados, además de exponer palabras como acciones
  semánticas y permitir activación con teclado.
- `test/features/reader/widgets/word_detail_sheet_test.dart`
  valida reproducción remota, aviso de fallback TTS y etiqueta semántica del
  botón de pronunciación.
- `test/features/stories/widgets/story_card_test.dart`
  valida que cada historia exponga una acción semántica descriptiva.
- `test/features/vocabulary/widgets/vocabulary_page_test.dart`
  valida etiqueta semántica de palabra guardada y tooltip del menú de acciones.

## Identificadores de prueba

Los widgets críticos exponen `Key`s centralizadas en
`lib/core/constants/app_keys.dart`.

Cobertura actual:

- login: correo, contraseña, mostrar contraseña y submit
- historias: listado y tarjetas por historia
- lector: scroll, contenido y palabras tocables
- lector: botón de ajustes, panel, tamaño de texto e interlineado
- palabra: pronunciación con audio remoto o fallback TTS
- historias: listado responsive con lista móvil y grid amplio
- accesibilidad: etiquetas semánticas en palabras, historias, progreso,
  pronunciación y vocabulario
- teclado: activación de palabras del lector con Enter o Espacio
- vocabulario: listado, filas, menú de acciones y edición de notas

## E2E Web con API real

La suite Playwright vigente valida Chrome sobre Flutter Web renderizado contra
`english_reader_api` real. En este SDK, `integration_test` no ejecuta tests Web
con `flutter test -d chrome`, por lo que se mantiene un smoke de widgets en
`test/flows` y el E2E visual vive en `e2e/`.

Referencia: https://playwright.dev/

Flujos implementados:

- login cliente desde la UI real
- listado de historias con búsqueda visible
- apertura de historia
- toque/clic en palabra desde el lector
- visualización de modal de significado
- guardado idempotente de palabra
- navegación y render de vocabulario
- verificación visual anti-lienzo blanco en escritorio y viewport móvil

Antes del flujo visual, el test asegura por API admin la palabra `umbrella` en
el diccionario local. Si ya existe, continúa con `409` esperado; así no depende
de proveedores externos de diccionario o traducción.

Comandos vigentes:

```bash
npm install
npx playwright install chrome
npm run e2e:web
npm run e2e:web:report
```

Las credenciales E2E se leen desde variables de entorno. Los defaults locales
solo se permiten contra `localhost`, `127.0.0.1` o `10.0.2.2` fuera de CI. En
CI, staging o una API remota, deben definirse `E2E_CLIENT_EMAIL`,
`E2E_CLIENT_PASSWORD`, `E2E_ADMIN_EMAIL` y `E2E_ADMIN_PASSWORD` según el flujo.

## Integración con API

Las pruebas deben validar que Flutter maneja correctamente:

- respuestas exitosas
- errores amigables
- tokens expirados
- archivos protegidos
- falta de audio remoto con fallback TTS

El smoke real vigente se ejecuta con:

```bash
dart run tool/verify_real_api_flow.dart
```

La validación visual Web vigente se ejecuta con:

```bash
npm run e2e:web
```

## Criterios de cierre

Este documento se considera suficiente cuando define:

- unit tests
- widget tests
- integración
- E2E con Playwright para Flutter Web
- smoke de flujo con rutas y BLoC reales
- flujos principales de lectura
- manejo de errores
