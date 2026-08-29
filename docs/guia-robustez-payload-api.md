# Guia de robustez de payload API - Readeriz

## Objetivo

La app no debe asumir que toda respuesta de la API llega con la forma exacta
esperada. Si el backend cambia un campo, devuelve `data` vacio donde no debe o
entrega un tipo inesperado, Flutter debe fallar con un mensaje controlado y no
con errores tecnicos como `TypeError` o `Null check operator used on a null
value`.

## Regla vigente

Toda respuesta normalizada debe cumplir:

```text
{
  success: bool,
  message: string opcional,
  data: objeto/lista/null segun endpoint,
  meta: objeto opcional
}
```

La validacion central vive en:

```text
lib/core/network/api_client.dart
lib/core/network/payload_guard.dart
```

## Como se usa

Los datasources deben:

- usar `response.requireData()` cuando el endpoint debe devolver `data`;
- usar `requirePayloadMap()` o `requirePayloadMapField()` antes de leer mapas
  anidados;
- envolver el parseo de modelos con `parseApiPayload()`.

Ejemplo:

```dart
return parseApiPayload(() {
  final data = response.requireData();
  return WordDetailModel.fromJson(requirePayloadMapField(data, 'word'));
});
```

## Resultado esperado

Si el payload esta incompleto o mal formado, la app lanza un `AppException` con
codigo estable:

```text
invalid_payload
```

La UI recibe un error amigable en vez de un fallo tecnico. Esto protege Web,
Android e iOS porque la validacion ocurre antes de llegar a widgets, BLoC o
pantallas.

## Pruebas

La cobertura principal esta en:

```text
test/core/network/api_payload_test.dart
```

Comandos recomendados:

```bash
flutter test test/core/network/api_payload_test.dart
flutter analyze
flutter test --reporter expanded
```
