# Guía de caché de recursos privados

## Para qué sirve

Las portadas y el audio de las historias no son archivos públicos: la API los
entrega solo con una sesión activa, desde `/files/story-assets/{id}`. Eso
significa que **no se pueden poner en un `Image.network`**, porque un `<img>`
no envía la cabecera `Authorization`.

La solución es descargarlos como bytes con el cliente HTTP autenticado y
guardarlos en memoria para no volver a pedirlos. De eso se encarga
`StoryAssetLoader`.

Como son datos privados de un usuario, esa memoria **se vacía cada vez que
cambia la sesión**. Un recurso descargado por una cuenta no debe quedar visible
para la siguiente que entre en el mismo proceso.

---

## Dónde está

| Archivo | Rol |
|---|---|
| `lib/core/media/story_asset_loader.dart` | La caché: descarga, guarda y reutiliza. |
| `lib/core/auth/session_scoped_cache.dart` | Interfaz que marca una caché como «propia de la sesión». |
| `lib/app/di/app_dependencies.dart` | Crea el cargador y lo registra en `sessionCaches`. |
| `lib/main.dart` | Lo publica con `Provider.value` para que los widgets lo lean. |
| `lib/features/stories/presentation/widgets/story_cover_image.dart` | Consumidor: portadas. |
| `lib/features/reader/presentation/pages/reader_page.dart` | Consumidor: audio de narración. |

---

## Cómo funciona

`load(assetId, {cache = true})` resuelve tres situaciones:

1. **Ya está descargado** → devuelve los bytes de memoria, sin red.
2. **Se está descargando ahora** → devuelve la *misma* petición en curso. Esto
   importa: una lista de historias puede pedir la misma portada desde varias
   tarjetas a la vez, y sin esto saldrían varias descargas idénticas.
3. **No está** → lo pide a la API y lo guarda.

El parámetro `cache: false` descarga pero **no guarda**. Se usa para el audio de
narración, que puede pesar varios megabytes y no compensa mantener en memoria.

```dart
// Portada: se guarda, porque es pequeña y se vuelve a ver al navegar.
final bytes = context.read<StoryAssetLoader>().load(cover.id);

// Audio: se descarga y se descarta al salir del lector.
final audio = context.read<StoryAssetLoader>().load(assetId, cache: false);
```

---

## Cuándo se vacía

`StoryAssetLoader` implementa `SessionScopedCache`, y `AuthRepositoryImpl` vacía
todas las cachés registradas en las tres transiciones de sesión:

| Momento | Por qué |
|---|---|
| Cerrar sesión | Los recursos del usuario no deben sobrevivir a su salida. |
| Iniciar sesión | Puede ser **otra cuenta** en el mismo proceso. |
| Sesión ya no válida | Expiró, o se cerró desde otro dispositivo. |

La limpieza vive en `AuthRepositoryImpl.clearSession()` y no en `AuthBloc`
porque hay cierres que no pasan por el bloc —una sesión invalidada de forma
remota, o una cookie vencida al arrancar—. Ese es el embudo por el que sí pasan
todos.

---

## Ejemplo: agregar una caché privada nueva

Supón que más adelante se cachean los avatares de usuario. Solo hacen falta dos
pasos para que se limpie sola:

```dart
// 1. Declara que su contenido pertenece a la sesión.
class AvatarLoader implements SessionScopedCache {
  final Map<String, Uint8List> _cache = {};

  @override
  void clear() => _cache.clear();
}
```

```dart
// 2. Regístrala en app_dependencies.dart
final authRepository = AuthRepositoryImpl(
  // ...
  sessionCaches: [storyAssetLoader, avatarLoader],
);
```

No hay que tocar el bloc, el logout ni el flujo de sesión.

---

## Cosas a tener en cuenta

- **No uses `Image.network` con una URL de `/files/...`**: fallará con 401. Pasa
  siempre por `StoryAssetLoader`.
- **No guardes bytes privados en otro sitio** (una variable estática, un
  singleton propio) sin implementar `SessionScopedCache`. Quedarían fuera de la
  limpieza y reaparecería el problema que esto resuelve.
- **La caché no tiene límite de tamaño** todavía. Con muchas portadas grandes el
  consumo de memoria crece sin tope. Está registrado como hallazgo abierto
  **FLT-SEC-012** en la auditoría; la solución prevista es un LRU con límite por
  bytes y cantidad.

---

## Referencias

- `docs/guia-sesion-web-tokens.md` — ciclo de vida de la sesión y tokens.
- `.handoff/auditoria-seguridad-flutter-readeriz.md` — hallazgos FLT-SEC-005 y FLT-SEC-012.
