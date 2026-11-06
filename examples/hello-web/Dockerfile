# Minimal multi-arch image used to exercise reusable-container.
FROM nginxinc/nginx-unprivileged:stable-alpine
USER root
# Pick up security fixes that are newer than the base image.
RUN apk upgrade --no-cache
COPY index.html /usr/share/nginx/html/index.html
USER 101
