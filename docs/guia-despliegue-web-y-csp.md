# Guía de despliegue Web y CSP

## Para qué sirve

`flutter build web` produce archivos estáticos: `index.html`, `main.dart.js`, la
carpeta `canvaskit/` y los assets. Esos archivos **no pueden protegerse solos**.

La Content-Security-Policy es una **cabecera HTTP**: la manda el servidor en cada
respuesta, no la app. Por eso el despliegue incluye nginx, que es quien la
aplica junto a las demás cabeceras de seguridad.

La CSP limita el daño si algún día se cuela una inyección: aunque un atacante
logre meter HTML, el navegador se niega a ejecutar scripts que no vengan del
propio origen, a cargar recursos externos o a incrustar la app en un iframe
ajeno.

---

## Dónde está

| Archivo | Rol |
|---|---|
| [`Dockerfile`](../Dockerfile) | Compila la app y arma la imagen con nginx. |
| [`docker/default.conf.template`](../docker/default.conf.template) | Configuración de nginx: cabeceras, caché y ruteo SPA. |
| [`.dockerignore`](../.dockerignore) | Lo que no entra a la imagen. |
| [`web/splash.js`](../web/splash.js) | Script de la pantalla de carga, en archivo aparte. |
| `assets/fonts/` | Roboto empaquetada (regular, medium, bold) + su licencia. |

---

## Las tipografías van empaquetadas, y no es opcional

El tema declara `fontFamily: 'Roboto'`. Si esa fuente no está en el bundle,
CanvasKit **la descarga de `fonts.gstatic.com` en cada carga**. Y si ese dominio
no responde —red corporativa que lo bloquea, bloqueador de anuncios, sin
conexión— la app se dibuja **sin una sola letra**: se ven los iconos y las cajas,
pero todo el texto es invisible.

Por eso `assets/fonts/` no es un detalle estético. Los archivos vienen del propio
SDK de Flutter (`bin/cache/artifacts/material_fonts/`), con licencia Apache 2.0,
y su presencia es lo que permite que `font-src` sea `'self'` sin excepciones.

**Si agregas una familia nueva, empaquétala.** No uses `google_fonts` ni un
`<link>` a un CDN: reintroduce la dependencia externa y obliga a abrir la CSP.

---

## La política, directiva por directiva

```
default-src 'self';
script-src 'self' 'wasm-unsafe-eval';
style-src  'self' 'unsafe-inline';
img-src    'self' data: blob:;
font-src   'self';
connect-src 'self' <origen de la API>;
object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'
```

| Directiva | Por qué así |
|---|---|
| `script-src 'self'` | No hay scripts en línea: el del splash vive en `splash.js`. |
| `'wasm-unsafe-eval'` | CanvasKit instancia WebAssembly. Sin esto la app no arranca. |
| **sin** `'unsafe-eval'` | Posible solo porque la imagen compila con `--csp`. Ver abajo. |
| `style-src 'unsafe-inline'` | Inevitable: el runtime de Flutter inyecta estilos al montarse. |
| `img-src … blob:` | Las portadas privadas se descargan autenticadas y se muestran como URL de objeto. |
| `font-src 'self'` | Las tipografías van empaquetadas. |
| `connect-src` | Solo el origen de la API. Se calcula en la construcción. |
| `frame-ancestors 'none'` | Impide incrustar la app en otro sitio (clickjacking). |

Además: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy` y HSTS
—esta última solo surte efecto sobre HTTPS; en HTTP el navegador la ignora—.

---

## Cómo se construye

```bash
docker build -t readeriz-web \
  --build-arg API_BASE_URL=https://api.readeriz.com/api/v1 \
  --build-arg APP_ENV=production .

docker run -p 8080:8080 readeriz-web
```

`API_BASE_URL` es obligatorio y **cumple dos funciones a la vez**: se compila
dentro de la app con `--dart-define` y, del mismo valor, se deriva el origen que
`connect-src` permite. Una sola fuente de verdad, para que la app no pueda
terminar hablando con una API que su propia política bloquea.

Consecuencia a tener presente: **la imagen queda ligada a un ambiente.** Flutter
congela la URL en tiempo de compilación, así que staging y producción son dos
construcciones distintas. No es como el panel administrativo, que sí resuelve su
URL en tiempo de ejecución.

La imagen corre como usuario no root y escucha en el **8080**.

---

## Qué no romper

- **No quites `--csp` del build.** Esa bandera desactiva la generación dinámica
  de código en la salida de Dart. Sin ella, la app necesita `'unsafe-eval'` y
  **deja de cargar** bajo esta política. Es el error más fácil de cometer y el
  más difícil de diagnosticar: la app simplemente no arranca.
- **No quites `--no-web-resources-cdn`.** Sirve CanvasKit desde el mismo origen;
  sin ella se pide a un CDN de Google y la CSP lo bloquea.
- **No agregues orígenes de terceros a `connect-src`** sin decidirlo
  explícitamente: es la puerta por la que la app puede empezar a hablar con
  servidores ajenos.
- **`style-src 'unsafe-inline'` no se puede quitar** hoy. Ya se comprobó que las
  violaciones no vienen del `index.html`, sino del runtime de Flutter.

---

## Cómo verificarlo

Con la imagen corriendo, en las DevTools del navegador:

1. **Network → la petición del documento → Headers**: debe aparecer
   `Content-Security-Policy` junto a las otras cabeceras.
2. **Console**: no debe haber ningún mensaje que empiece con `Refused to…`.
   Cada uno de esos es una violación real.
3. **Network, filtrando por dominio**: no debe haber peticiones fuera del origen
   propio y del de la API. Ninguna a `gstatic.com` ni a `googleapis.com`.
4. **Prueba rápida en la consola**, para confirmar que `connect-src` está activo:

```js
await fetch('https://fonts.gstatic.com/')   // debe fallar
await fetch('<origen de la API>/health')    // debe responder 200
```

Si el texto se ve pero los iconos no, o al revés, casi siempre es una fuente que
no quedó empaquetada.

---

## Estado

La política se midió contra el build real: cero violaciones, cero orígenes
externos y texto renderizado con Google bloqueado por completo.

**La imagen todavía no se ha construido**, porque el equipo de desarrollo no
tiene Docker. La configuración y la política están verificadas; falta un
`docker build` real en un entorno que lo permita.

---

## Referencias

- [`docs/guia-ejecucion-ambientes-flutter.md`](guia-ejecucion-ambientes-flutter.md) — los `--dart-define` por ambiente.
- [`docs/guia-sesion-web-tokens.md`](guia-sesion-web-tokens.md) — la sesión en Web, que depende de `connect-src`.
- `.handoff/auditoria-seguridad-flutter-readeriz.md` — hallazgo FLT-SEC-008.
