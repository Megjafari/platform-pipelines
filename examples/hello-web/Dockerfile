# Minimal multi-arch image used to exercise reusable-container.
# mainline gets nginx security fixes first. stable-alpine kept nginx 1.30.6 for weeks after 1.30.7 fixed CVEs.
FROM nginxinc/nginx-unprivileged:mainline-alpine
USER root
# Pick up security fixes that are newer than the base image.
RUN apk upgrade --no-cache
COPY index.html /usr/share/nginx/html/index.html
USER 101
