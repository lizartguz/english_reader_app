# ==========================================================
# Readeriz Web - imagen de produccion
#
# Compila la app con Flutter y sirve el resultado estatico desde nginx, que es
# quien aplica la Content-Security-Policy y las demas cabeceras de seguridad
# (hallazgo FLT-SEC-008): un archivo estatico no puede imponerlas por si solo.
#
# La imagen queda ligada a un ambiente porque Flutter congela `API_BASE_URL` en
# tiempo de compilacion (`--dart-define`). Por eso el mismo valor se usa para
# dos cosas: compilar la app y calcular el origen que la CSP permite en
# `connect-src`. Una sola fuente de verdad evita que la app hable con una API
# que la politica bloquea.
#
#   docker build -t readeriz-web \
#     --build-arg API_BASE_URL=https://api.readeriz.com/api/v1 \
#     --build-arg APP_ENV=production .
# ==========================================================

# ----- Etapa 1: compilacion -----
FROM ghcr.io/cirruslabs/flutter:3.44.8 AS build

ARG API_BASE_URL
ARG APP_ENV=production

WORKDIR /app

# Los manifiestos van primero para aprovechar la cache de capas: mientras las
# dependencias no cambien, no se vuelven a resolver al tocar el codigo.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# `--csp` desactiva la generacion dinamica de codigo, que es lo que obligaria a
# permitir 'unsafe-eval'. `--no-web-resources-cdn` sirve CanvasKit desde el
# mismo origen en vez de traerlo de un CDN externo.
RUN test -n "$API_BASE_URL" || (echo "Falta --build-arg API_BASE_URL" && exit 1) && \
    flutter build web --release --csp --no-web-resources-cdn \
      --dart-define=API_BASE_URL="$API_BASE_URL" \
      --dart-define=APP_ENV="$APP_ENV"

# La CSP razona en origenes (esquema + host + puerto), no en rutas: de
# `https://api.ejemplo.com/api/v1` solo interesa `https://api.ejemplo.com`.
COPY docker/default.conf.template /tmp/default.conf.template
RUN API_ORIGIN=$(printf '%s' "$API_BASE_URL" | sed -E 's#^(https?://[^/]+).*#\1#') && \
    sed "s|\${API_ORIGIN}|$API_ORIGIN|g" /tmp/default.conf.template > /tmp/default.conf && \
    echo "CSP: connect-src permitira $API_ORIGIN"

# ----- Etapa 2: servidor estatico -----
# Imagen sin privilegios: corre como usuario no root y escucha en el 8080.
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

COPY --from=build /app/build/web /usr/share/nginx/html
COPY --from=build /tmp/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/ || exit 1
