# Pruebas y calidad Flutter - English Reader

## Objetivo

Este documento define pruebas de calidad para `english_reader_app`.

## Tipos de pruebas

La estrategia debe incluir:

```text
unit tests
widget tests
integration tests
e2e tests para Flutter Web
```

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
- `test/features/reader/reader_bloc_test.dart`
  valida carga de historia, restauración de progreso y sincronización silenciosa.
- `test/features/reader/reader_settings_cubit_test.dart`
  valida carga, límites, guardado y restablecimiento de preferencias del lector.
- `test/features/reader/word_detail_test.dart`
  valida la selección del primer audio remoto válido para pronunciación.
- `test/features/stories/stories_page_test.dart`
  valida que historias use lista en móvil y grid en tablet/Web.

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
  semánticas.
- `test/features/reader/widgets/word_detail_sheet_test.dart`
  valida reproducción remota, aviso de fallback TTS y etiqueta semántica del
  botón de pronunciación.
- `test/features/stories/widgets/story_card_test.dart`
  valida que cada historia exponga una acción semántica descriptiva.

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
- accesibilidad: etiquetas semánticas en palabras, historias y pronunciación
- vocabulario: listado, filas, menú de acciones y edición de notas

## E2E con Playwright para Flutter Web

Se usará Playwright para validar flujos principales en Flutter Web.

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

## Criterios de cierre

Este documento se considera suficiente cuando define:

- unit tests
- widget tests
- integración
- E2E con Playwright para Flutter Web
- flujos principales de lectura
- manejo de errores
