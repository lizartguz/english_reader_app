# Navegación y experiencia de usuario - English Reader App

## Objetivo

Este documento define navegación, salida con doble back, mensajes, loaders, errores y responsive.

## Navegación

Se recomienda usar `go_router`.

Rutas principales:

```text
/splash
/login
/home
/stories
/stories/:id
/reader/:storyId
/vocabulary
/profile
```

## Rutas protegidas

Las rutas internas deben requerir sesión válida.

Si no hay sesión:

```text
redirigir a /login
```

Si la sesión expiró:

```text
mostrar mensaje amigable y redirigir a /login
```

## Doble back para salir

En la pantalla principal, al presionar atrás una vez:

```text
Presiona nuevamente para salir.
```

Si el usuario presiona atrás nuevamente dentro del intervalo definido, la app puede salir o minimizarse según plataforma.

Recomendación técnica:

- usar `PopScope` en Flutter moderno
- aplicar solo en Android cuando corresponda
- no forzar cierre en Web
- en iOS respetar comportamiento nativo

Intervalo sugerido:

```text
2 segundos
```

El flujo vigente aplica `PopScope` solo en Android nativo desde la pantalla
principal de historias. Web e iOS conservan su comportamiento de navegación
propio.

## Loaders

Debe existir un componente reutilizable de carga.

Usos:

- verificando sesión
- cargando historias
- abriendo lectura
- consultando palabra
- guardando vocabulario
- sincronizando progreso

No se deben crear loaders diferentes en cada pantalla.

## Mensajes amigables

Todos los mensajes deben estar en español y no ser técnicos.

Ejemplos:

```text
No se pudo conectar con el servidor. Inténtalo nuevamente en unos minutos.
Tu sesión ha expirado. Inicia sesión nuevamente.
Tu sesión fue cerrada porque se inició en otro dispositivo.
No se pudo consultar la palabra.
Palabra guardada correctamente.
```

## API caída

Si la API no responde, mostrar:

```text
No se pudo conectar con el servidor. Inténtalo nuevamente en unos minutos.
```

No mostrar stack traces, errores crudos de red ni detalles técnicos.

## No autorizado

Si la API indica falta de autorización:

```text
No tienes permiso para realizar esta acción.
```

## Accesibilidad operativa

El lector debe permitir seleccionar palabras tanto con gesto táctil/clic como
con teclado. Las palabras consultables aceptan Enter y Espacio cuando tienen el
foco.

El indicador de progreso del lector expone una etiqueta semántica con el
porcentaje visible. Las filas de vocabulario exponen palabra, traducción y
estado, y el menú de acciones usa un tooltip específico por palabra.

## Responsive

La app debe funcionar en:

```text
Android
iOS
Web
```

Criterios:

- lectura cómoda en móvil
- ancho máximo de lectura en Web
- modal/bottom sheet usable en pantallas pequeñas
- controles táctiles claros
- textos sin desbordes

La implementación Flutter usa breakpoints compartidos:

- `< 600px`: composición compacta para móvil.
- `>= 900px`: composición amplia para tablet/Web.
- `>= 1200px`: padding lateral mayor para escritorio.

El listado de historias se muestra como lista en móvil y como grid en
tablet/Web. Las pantallas de vocabulario y perfil centran su contenido con ancho
máximo para conservar lectura rápida en escritorio.

## Criterios de cierre

Este documento se considera suficiente cuando define:

- rutas principales
- rutas protegidas
- doble back
- loaders
- mensajes amigables
- API caída
- no autorizado
- accesibilidad operativa
- responsive
