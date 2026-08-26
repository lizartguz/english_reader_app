# Sesión, seguridad y dispositivo único - English Reader App

## Objetivo

Este documento define persistencia de sesión, almacenamiento seguro y política de un solo dispositivo por usuario cliente.

## Persistencia de sesión

La app debe evitar pedir login nuevamente si existe una sesión válida.

Flujo de arranque:

```text
abrir app
  -> leer flag local de sesión
  -> leer tokens desde almacenamiento seguro
  -> leer device_id
  -> verificar sesión con API
  -> si es válida, entrar a la app
  -> si no es válida, limpiar sesión y mostrar login
```

## SharedPreferences

Uso permitido:

- flag `is_logged_in`
- tema visual
- preferencias de lectura
- último tamaño de fuente
- último acento TTS seleccionado
- datos no sensibles de UI

No debe guardar tokens, contraseñas ni secretos.

## Flutter Secure Storage

Uso recomendado:

- access token
- refresh token
- device_id

El `device_id` identifica la instalación/dispositivo y debe mantenerse incluso después de cerrar sesión, salvo que se limpie la app o se reinstale.

## Device ID

La app debe generar un `device_id` si no existe.

Debe enviarse a la API en:

- login
- refresh token
- verify session
- logout

Datos recomendados:

```text
device_id
platform
app_version
device_name opcional
```

## Un solo dispositivo por usuario

La regla de negocio será:

```text
un usuario CLIENT solo puede tener una sesión activa en un dispositivo a la vez
```

Flujo recomendado:

```text
usuario inicia sesión en dispositivo B
  -> API invalida sesión activa anterior del dispositivo A
  -> dispositivo B queda activo
  -> dispositivo A recibe sesión invalidada en su siguiente request
  -> dispositivo A limpia sesión local y vuelve al login
```

Mensaje sugerido:

```text
Tu sesión fue cerrada porque se inició en otro dispositivo.
```

## Expiración y refresh

La app debe manejar:

- access token expirado
- refresh token válido
- refresh token inválido
- sesión invalidada por otro dispositivo
- usuario bloqueado o inactivo

Si la sesión no puede renovarse, debe limpiar datos locales y redirigir al login.

## Limpieza de sesión

Al cerrar sesión o detectar sesión inválida:

- eliminar tokens
- marcar `is_logged_in` como falso
- limpiar usuario local
- limpiar permisos locales
- limpiar caché sensible

No eliminar el `device_id` salvo decisión explícita.

## Seguridad

Reglas:

- no imprimir tokens en logs
- no guardar tokens en `shared_preferences`
- no mostrar errores técnicos al usuario
- no confiar solo en validaciones locales
- validar sesión con API al iniciar

## Criterios de cierre

Este documento se considera suficiente cuando define:

- persistencia de sesión
- uso correcto de SharedPreferences
- uso de Flutter Secure Storage
- device id
- un dispositivo por usuario
- refresh y expiración
- limpieza de sesión
