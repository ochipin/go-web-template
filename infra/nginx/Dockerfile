ARG NGINX_VERSION=1.27
FROM --platform=$BUILDPLATFORM nginx:${NGINX_VERSION} AS base

COPY /infra/nginx/entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
