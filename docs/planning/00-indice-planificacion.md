# Índice de planificación - English Reader App

Este directorio contiene la planificación técnica del proyecto `english_reader_app`.

El objetivo es definir arquitectura, experiencia de lectura, integración con API y criterios de despliegue antes de implementar la aplicación Flutter.

## Ecosistema del proyecto

English Reader está compuesto por tres proyectos relacionados:

```text
english_reader_api    -> Backend NestJS, API, seguridad, reglas de negocio, persistencia e integraciones.
english_reader_admin  -> Panel administrativo React para gestión visual de contenido, usuarios, roles y configuración.
english_reader_app    -> Aplicación Flutter para Android, iOS y Web orientada al usuario cliente.
```

Flutter debe consumir datos y reglas desde `english_reader_api`. No debe consultar directamente base de datos ni proveedores externos de diccionario/traducción.

## Ubicación local de proyectos

En el entorno local actual, los proyectos se encuentran en:

```text
C:\xampp\htdocs\english_reader_api    -> Backend NestJS y API.
C:\xampp\htdocs\english_reader_admin  -> Panel administrativo React.
C:\xampp\htdocs\english_reader_app    -> Aplicación Flutter.
```

## Documentos

1. `01-arquitectura-flutter.md`
   - Define arquitectura general, capas, features, estado, navegación y relación con la API.

2. `02-experiencia-lectura.md`
   - Define experiencia de lectura, reproductor, selección de palabras, modal de significado y vocabulario.

3. `03-integracion-api-flutter.md`
   - Define consumo de API, autenticación, errores, tokens, archivos protegidos y sincronización de datos.

4. `04-operacion-despliegue-flutter.md`
   - Define criterios de build, ambientes, configuración y despliegue Android, iOS y Web.

5. `05-pruebas-calidad-flutter.md`
   - Define pruebas de Flutter, flujos de lectura, integración API y E2E con Playwright para Flutter Web.

6. `06-librerias-dependencias-flutter.md`
   - Define plugins y paquetes aprobados o recomendados para estado, navegación, almacenamiento, API, TTS, imágenes y pruebas.

7. `07-estado-bloc-provider.md`
   - Define el uso de BLoC, Cubit, Provider, repositorios, servicios y separación de responsabilidades.

8. `08-sesion-seguridad-dispositivo.md`
   - Define persistencia de sesión, almacenamiento seguro, verificación con API y política de un solo dispositivo por usuario.

9. `09-navegacion-experiencia-usuario.md`
   - Define navegación, rutas, doble back para salir, mensajes, loaders, errores y responsive.

10. `10-estandares-codigo-flutter.md`
   - Define estándares Dart/Flutter, imports, constantes, comentarios, modelos, servicios y widgets reutilizables.

## Guias permanentes relacionadas

- `../guia-robustez-payload-api.md`
  - Define como validar respuestas inesperadas de la API antes de castear o
    construir modelos en Flutter.

## Regla de impacto cruzado

Cuando cambien endpoints, modelos, permisos, validaciones o formatos de respuesta en `english_reader_api`, se debe revisar el impacto en Flutter.
