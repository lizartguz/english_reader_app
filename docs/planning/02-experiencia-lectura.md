# Experiencia de lectura - English Reader App

## Objetivo

Este documento define la experiencia principal de lectura en Flutter.

## Flujo principal

```text
CLIENT inicia sesión
  -> ve historias disponibles
  -> selecciona una historia
  -> abre la vista de lectura
  -> reproduce o pausa audio/lectura
  -> toca una palabra
  -> ve significado, traducción y pronunciación
  -> guarda palabra en vocabulario si lo desea
  -> progreso se sincroniza con la API
```

## Lista de historias

La app debe mostrar historias publicadas desde la API.

Información sugerida:

- título
- resumen
- nivel
- imagen autorizada si existe
- duración estimada
- progreso del usuario si existe

## Vista de lectura

La vista debe permitir:

- leer el contenido de la historia
- pausar o reproducir lectura/audio
- tocar palabras
- consultar significado
- guardar vocabulario
- registrar progreso

## Modal de palabra

Al tocar una palabra, se debe abrir una ventana modal o bottom sheet.

Debe mostrar:

- palabra
- definición en inglés
- traducción al español
- fonética
- tipo gramatical
- ejemplos si existen
- botón de pronunciación
- acción para guardar en vocabulario

Los mensajes deben ser amigables y en español.

## Pronunciación

La app debe reproducir audio remoto cuando la API lo entregue.

Si no existe audio remoto, o si la URL falla, usa texto a voz local como
respaldo.

Librería sugerida:

```text
flutter_tts
```

Esta librería queda aprobada como base para texto a voz en Flutter.

La reproducción vigente prioriza `pronunciations[].audioUrl` y muestra en el
modal si se está usando audio remoto o voz del dispositivo.

## Vocabulario

El usuario puede guardar palabras consultadas.

Estados conceptuales:

```text
saved
learning
learned
archived
```

La API debe evitar duplicados por usuario y palabra.

La pantalla de vocabulario permite:

- listar palabras guardadas
- cambiar estado entre `saved`, `learning`, `learned` y `archived`
- guardar notas de estudio
- eliminar una palabra del vocabulario personal sin borrar el diccionario global

## Progreso de lectura

La app debe sincronizar progreso con la API.

Datos conceptuales:

```text
progress_percent
last_position
completed_at
last_read_at
```

La vista de lectura calcula `progress_percent` a partir del scroll vertical.
El valor vigente de `last_position` usa el formato:

```text
scroll:<offset_en_pixeles>
```

Al reabrir una historia, Flutter restaura la posición si la API entrega ese
formato.

La sincronización de progreso convive con preferencias locales del lector. Esas
preferencias no se envían a la API porque solo afectan la comodidad visual del
dispositivo actual.

## Responsividad

Flutter Web debe adaptarse a escritorio y móvil.

La experiencia de lectura debe cuidar:

- tamaño de texto
- espacios cómodos
- modal usable en pantallas pequeñas
- controles táctiles
- scroll fluido

## Accesibilidad y personalización

La experiencia de lectura debe ser fácil de mantener y personalizar.

Las configuraciones visuales no deben estar duplicadas en cada pantalla. Deben
centralizarse para que un cambio se aplique en varias partes de la app.

Configuraciones centralizadas:

- tamaño base de texto
- escala del texto de lectura
- altura de línea
- contraste
- paleta de colores
- estilos de botones
- tamaño mínimo de controles táctiles
- espaciados de lectura
- estilos de modal y bottom sheet
- etiquetas semánticas para lectores de pantalla

La vista de lectura debe respetar la configuración global de accesibilidad.

El lector expone un panel de ajustes con controles para:

- escala de texto de lectura
- altura de línea
- restablecer valores cómodos por defecto

Estos valores se guardan en `shared_preferences` con las claves
`reader_font_scale` y `reader_line_height`.

Ejemplos:

```text
Cambiar tamaño de texto de lectura
  -> afecta vista de lectura, modal de palabra y ejemplos

Cambiar contraste
  -> afecta fondo, texto, botones y estados activos

Cambiar tamaño mínimo táctil
  -> afecta botones de reproducción, pausa, guardar y cerrar
```

La app debe evitar textos demasiado pequeños, controles difíciles de pulsar o
colores con contraste bajo.

Las palabras tocables del lector, las tarjetas de historia y los controles de
pronunciación exponen etiquetas semánticas para lectores de pantalla.

## Criterios de cierre de este documento

Este documento se considera suficiente cuando define:

- flujo de lectura
- lista de historias
- vista de lectura
- modal de palabra
- pronunciación
- vocabulario
- progreso
- responsividad
- accesibilidad y personalización centralizada
