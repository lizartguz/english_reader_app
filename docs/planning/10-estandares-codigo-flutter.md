# Estándares de código Flutter - English Reader App

## Objetivo

Este documento define estándares de código para futuras implementaciones Flutter/Dart.

## Imports

Usar imports al inicio del archivo.

Evitar referencias largas inline.

Ejemplo recomendado:

```dart
import '../models/story.dart';

Future<Story> getStory(String id);
```

Evitar:

```dart
Future<import('../models/story.dart').Story> getStory(String id);
```

## Constantes y enums

No hardcodear strings reutilizables.

Centralizar:

- rutas
- nombre y datos de marca de la app
- claves de storage
- estados
- mensajes
- códigos de error
- nombres de features
- valores de configuración

Ejemplo:

```dart
enum AuthStatus {
  initial,
  checking,
  authenticated,
  unauthenticated,
  sessionExpired,
}
```

## Comentarios

Usar comentarios breves en español cuando aporten claridad.

Formato recomendado:

```dart
/// Verifica con la API si la sesión local sigue vigente.
Future<void> verifySession();
```

No comentar código obvio.

Comentar especialmente:

- seguridad
- sesión
- device id
- BLoC con reglas complejas
- sincronización de progreso
- fallback TTS
- errores no obvios

## Widgets

Los widgets deben ser pequeños y reutilizables.

Reglas:

- no crear pantallas enormes
- separar widgets del lector
- separar modal de palabra
- separar componentes de loading/error/empty
- evitar lógica API dentro del widget

## Accesibilidad

Los controles que no se explican bien solo con su texto visible deben usar
etiquetas semánticas centralizadas en `AppSemantics`.

Los widgets interactivos de lectura y vocabulario deben considerar teclado y
lector de pantalla cuando se usen en Web/escritorio. Las acciones no textuales
requieren tooltip y las etiquetas semánticas reutilizables deben vivir en
`AppSemantics`.

## Servicios

Los servicios deben centralizar:

- llamadas API
- manejo de tokens
- refresh
- errores
- archivos protegidos

No hacer llamadas HTTP directamente desde widgets.

## BLoC

Cada BLoC debe tener:

- eventos claros
- estados claros
- errores amigables
- dependencias inyectadas
- lógica de negocio fuera de widgets

## Storage

Reglas:

- tokens en `flutter_secure_storage`
- flags y preferencias en `shared_preferences`
- claves centralizadas
- limpieza de sesión centralizada

## Marca

El nombre visible de la app en Flutter debe leerse desde `AppInfo.displayName`.
Los nombres nativos se centralizan por plataforma: `@string/app_name` en Android
y `APP_DISPLAY_NAME` en los `.xcconfig` de iOS.

## Criterios de cierre

Este documento se considera suficiente cuando define:

- imports
- constantes/enums
- comentarios
- widgets
- servicios
- BLoC
- storage
