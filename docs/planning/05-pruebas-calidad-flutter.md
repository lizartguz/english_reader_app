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

Se usará Playwright contra Chrome para validar flujos principales en Flutter Web
cuando la API local esté disponible. En este SDK, `integration_test` no ejecuta
tests Web con `flutter test -d chrome`, por lo que el smoke vigente vive en
`test/flows`.

Referencia: https://playwright.dev/

Flujos prioritarios:

- login cliente
- listado de historias
- apertura de historia
- reproducción o pausa
- toque/clic en palabra
- visualización de modal de significado
- pronunciación disponible
- guardar palabra
- sincronizar progreso
- sesión expirada

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

## Criterios de cierre

Este documento se considera suficiente cuando define:

- unit tests
- widget tests
- integración
- E2E con Playwright para Flutter Web
- smoke de flujo con rutas y BLoC reales
- flujos principales de lectura
- manejo de errores
