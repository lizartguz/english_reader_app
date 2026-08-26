# Arquitectura Flutter - English Reader

## Objetivo

`english_reader_app` es la aplicación Flutter para usuarios cliente.

Debe funcionar para:

```text
Android
iOS
Web
```

## Ecosistema relacionado

```text
english_reader_api    -> NestJS: entrega historias, palabras, vocabulario, progreso y seguridad.
english_reader_admin  -> React: administra contenido que luego consume Flutter.
english_reader_app    -> Flutter: experiencia de lectura del usuario final.
```

Flutter no debe contener reglas críticas duplicadas. La API es la fuente de verdad.

## Enfoque arquitectónico

Se usará arquitectura limpia por features:

```text
Clean Architecture + Feature Modules
```

El patrón principal de estado será BLoC.

También se usará Provider para inyección de dependencias, servicios, configuración global ligera o elementos simples que no justifiquen un BLoC propio.

Regla:

```text
BLoC/Cubit -> estado de pantallas, casos de uso y flujos de negocio.
Provider   -> dependencias, servicios y estado simple de alcance global.
```

No se deben duplicar responsabilidades entre BLoC y Provider.

Estructura propuesta:

```text
lib/
  main.dart

  app/
    router/
    theme/
    accessibility/
    di/
    config/

  core/
    network/
    auth/
    storage/
    errors/
    layout/
    widgets/
    constants/
    accessibility/
    utils/

  features/
    auth/
    stories/
    reader/
    vocabulary/
    word_detail/
    profile/
```

La estructura detallada de BLoC, Provider, repositorios y servicios se documenta en `07-estado-bloc-provider.md`.

## Capas por feature

```text
features/{feature}/
  domain/
    entities/
    repositories/
    use_cases/

  data/
    models/
    datasources/
    repositories/

  presentation/
    pages/
    widgets/
    controllers/
    state/
```

## Equivalencia con estructura tradicional Flutter

En Flutter es común encontrar carpetas generales como `models`, `services`,
`screens`, `widgets`, `providers` o `bloc`.

En este proyecto no se usará una carpeta global para todo, porque eso puede
crecer de forma desordenada. La equivalencia será la siguiente:

```text
models/
  -> features/{feature}/data/models/

services/
  -> core/network/
  -> core/auth/
  -> core/storage/
  -> app/di/
  -> features/{feature}/data/datasources/

screens/ o pages/
  -> features/{feature}/presentation/pages/

widgets/
  -> core/widgets/
  -> features/{feature}/presentation/widgets/

providers/
  -> app/di/
  -> providers globales solo cuando sean necesarios
  -> MultiProvider / MultiRepositoryProvider en la raíz de la app

bloc/
  -> features/{feature}/presentation/bloc/

repositories/
  -> features/{feature}/domain/repositories/
  -> features/{feature}/data/repositories/

utils/
  -> core/utils/

constants/
  -> core/constants/

accessibility/
  -> app/accessibility/
  -> core/accessibility/

layout/
  -> core/layout/
```

Regla práctica:

- si el archivo pertenece solo a una funcionalidad, debe vivir dentro de su
  `feature`
- si el archivo será usado por varias funcionalidades, debe vivir en `core`
- si el archivo configura la aplicación completa, debe vivir en `app`

Ejemplo:

```text
AuthRemoteDataSource
  -> features/auth/data/datasources/

StoryModel
  -> features/stories/data/models/

ApiClient
  -> core/network/

StorageService
  -> core/storage/

AppRouter
  -> app/router/

AccessibilityConfig
  -> app/accessibility/

PrimaryButton
  -> core/widgets/

ReaderToolbar
  -> features/reader/presentation/widgets/
```

## Flujo

```text
Pantalla
  -> Controller/ViewModel
  -> Use Case
  -> Repository abstracto
  -> Repository implementation
  -> Remote datasource
  -> english_reader_api
```

## Principios

- consumir siempre la API
- no acceder a proveedores externos directamente
- mostrar errores amigables
- guardar tokens en almacenamiento seguro
- usar `shared_preferences` solo para datos no sensibles y preferencias
- separar UI, lógica y datos
- mantener modelos Dart alineados con contratos API
- preparar la app para Android, iOS y Web
- no implementar modo offline en la primera versión
- centralizar estilos, tamaños, colores, contraste y accesibilidad

## Contratos de modelos

Los modelos Dart deben estar alineados con los DTO y respuestas de
`english_reader_api`.

Reglas:

- no inventar campos en Flutter que no existan en el contrato de la API
- mapear las respuestas externas dentro de `data/models`
- exponer entidades limpias desde `domain/entities`
- mantener nombres consistentes con la API cuando representen el mismo dato
- ajustar modelos, datasources, repositories y BLoC cuando cambie un contrato de API

Ejemplo:

```text
StoryResponseDto en API
  -> StoryModel en Flutter data/models
  -> StoryEntity en Flutter domain/entities
```

## Estrategia offline

En la primera versión no se implementará modo offline.

La app dependerá de la API para:

- iniciar sesión
- listar historias
- abrir una historia
- consultar palabras
- guardar vocabulario
- sincronizar progreso

Si no hay conexión, Flutter debe mostrar un mensaje amigable y permitir reintentar.
No debe simular que la información está actualizada si no pudo comunicarse con la
API.

## Accesibilidad centralizada

La configuración visual y de accesibilidad debe centralizarse para facilitar el
mantenimiento.

Ubicaciones sugeridas:

```text
app/theme/
app/accessibility/
core/accessibility/
core/constants/
```

Debe poder personalizarse desde un solo lugar:

- tamaños de texto base
- escala de texto para lectura
- contraste de colores
- colores principales y secundarios
- estilos de botones y campos
- espaciados reutilizables
- tamaños mínimos de controles táctiles
- etiquetas semánticas para lectores de pantalla

Las pantallas no deben definir valores visuales críticos de forma aislada. Deben
consumir configuración centralizada para mantener consistencia en Android, iOS y
Web.

## Comentarios de código

Cuando la lógica lo requiera, se usarán comentarios breves en español con estilo Dart:

```dart
/// Consulta la palabra desde la API y permite mostrar su detalle al lector.
Future<WordDetail> lookupWord(String word);
```

No se debe comentar código obvio.

## Criterios de cierre de este documento

Este documento se considera suficiente cuando define:

- responsabilidad de Flutter
- relación con API y Admin
- arquitectura por features
- capas
- flujo de datos
- principios generales
