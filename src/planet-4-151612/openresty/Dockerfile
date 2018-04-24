# Greenpeace P4 Docker application
# Image: gcr.io/planet-4-151612/openresty:develop
# Build: build-530
# Date:  Tue Apr 24 05:25:09 UTC 2018
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------
  
FROM gcr.io/planet-4-151612/ubuntu:develop

LABEL authors="Raymond Walker <raymond.walker@greenpeace.org>"

EXPOSE 80
EXPOSE 443

ENV \
    APP_GID="1000" \
    APP_GROUP="nginx" \
    APP_UID="1000" \
    APP_USER="nginx" \
    APP_HOSTPATH="international" \
    CHOWN_APP_DIR="false" \
    CLOUDFLARE_ENABLED="false" \
    NGX_PAGESPEED_RELEASE="stable" \
    NGX_PAGESPEED_VERSION="latest" \
    OPENRESTY_FASTCGI_BACKEND="php-fpm:9000" \
    OPENRESTY_KEEPALIVE_TIMEOUT="30" \
    OPENRESTY_MAX_WORKER_PROCESSES="8" \
    OPENRESTY_SENDFILE="on" \
    OPENRESTY_SOURCE="source" \
    OPENRESTY_VERSION="1.13.6.1" \
    OPENSSL_VERSION="1.0.2n" \
    PAGESPEED_ADMIN_PATH="/_pagespeed_admin" \
    PAGESPEED_DISABLE_FILTERS="" \
    PAGESPEED_ENABLED="false" \
    PAGESPEED_REBEACON_KEY="uwuudeL7iedoo7Meengi" \
    PAGESPEED_REDIS_SERVER="redis:6379" \
    PAGESPEED_REWRITE_LEVEL="CoreFilters" \
    PAGESPEED_STATISTICS_ENABLED="off" \
    PHP_ENABLED="false" \
    REDIS_FASTCGI_CACHE_ENABLED="false" \
    REDIS_FASTCGI_CACHE_SERVER="redis:6379" \
    PUBLIC_PATH="/app/source/public" \
    SSL_ENABLED="false" \
    UPLOAD_MAX_SIZE="50M"

COPY . /app/

RUN set -ex && \
    groupadd -g "${APP_GID}" "${APP_GROUP}" && \
    useradd -r -s /usr/sbin/nologin "${APP_USER}" -u "${APP_UID}" -g "${APP_GID}" && \
    apt-get update && \
    bash /app/bin/install_openresty.sh && \
  	rm -Rf /tmp/* /var/tmp/* /var/lib/apt/lists/* && \
    rm -fr /usr/share/man/* /usr/share/doc/* /usr/share/locale/* && \
    mkdir -p /etc/nginx/ssl "/app/source/public" && \
    echo "$(nginx -V 2>&1)" > "/app/source/public/index.html" && \
    echo "TEST-DATA-ONLY" >> "/app/source/public/index.html"
