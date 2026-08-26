# Estado BLoC y Provider - English Reader App

## Objetivo

Este documento define cómo se manejará el estado en `english_reader_app`.

## Regla principal

El patrón principal será BLoC.

Provider se usará solo para dependencias, servicios o estado simple global.

## Uso de BLoC

Usar BLoC cuando exista:

- flujo con eventos claros
- estados de carga, éxito y error
- reglas de negocio
- interacción con API
- sincronización de datos
- acciones del usuario que cambian estado

Features con BLoC:

```text
auth
stories
reader
word_detail
vocabulary
profile
reading_progress
```

## Uso de Cubit

Usar Cubit para estados simples.

Ejemplos:

- tema
- tamaño de texto del lector
- preferencia de voz/acento
- estado visual sencillo

## Uso de Provider

Provider puede exponer:

- servicios
- repositorios
- configuración
- storage service
- cliente API
- preferencias no sensibles

No se debe usar Provider para duplicar estados que ya maneje un BLoC.

## Estructura por feature

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
    bloc/
      {feature}_bloc.dart
      {feature}_event.dart
      {feature}_state.dart
    pages/
    widgets/
```

## Estados comunes

Cada BLoC debe modelar estados claros:

```text
initial
loading
success
empty
error
unauthorized
sessionExpired
```

Los mensajes deben ser amigables y no técnicos.

## Inyección de dependencias

Los servicios y repositorios deben inyectarse desde la raíz de la app.

Patrones aceptados:

```text
MultiProvider
MultiRepositoryProvider
MultiBlocProvider
```

No se deben crear servicios manualmente dentro de widgets profundos.

## Referencia DentaSync

La app de referencia usa `MultiBlocProvider`, servicios centralizados y `StorageService`.

Para English Reader se rescata:

- inicialización centralizada
- BLoCs por dominio
- servicios inyectados
- separación entre storage seguro y preferencias

## Criterios de cierre

Este documento se considera suficiente cuando define:

- BLoC como patrón principal
- Cubit para estados simples
- Provider para dependencias
- estructura por feature
- estados comunes
- inyección centralizada
