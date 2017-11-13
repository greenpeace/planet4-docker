# Greenpeace P4 Docker application
# Image: gcr.io/planet-4-151612/wordpress:feature-php
# Build: build-228
# Date:  Mon Nov 13 10:25:07 UTC 2017
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------

FROM gcr.io/planet-4-151612/php-fpm:feature-php

MAINTAINER Raymond Walker <raymond.walker@greenpeace.org>

RUN apt-get update && \
    apt-get install -y --no-install-recommends rsync git mysql-client && \
    apt-get clean && \
    rm -Rf /tmp/* /var/tmp/* /var/lib/apt/lists/* && \
    curl --retry 5 -o /app/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    ln -s /app/bin/wp.sh /app/bin/wp

COPY . /app/

ENV OVERWRITE_FILES="false" \
    PHP_CLEAR_ENV="no" \
    WP_ADMIN_EMAIL="" \
    WP_ADMIN_NAME="" \
    WP_ADMIN_PASS="" \
    WP_ADMIN_USER="" \
    WP_DB_CHARSET="utf8" \
    WP_DB_COLLATION="" \
    WP_DB_HOST="db" \
    WP_DB_NAME="" \
    WP_DB_PASS="" \
    WP_DB_PORT="3306" \
    WP_DB_PREFIX="wp_" \
    WP_DB_USER="" \
    WP_FORCE_SSL_ADMIN="false" \
    WP_HOSTNAME="" \
    WP_LOCALE="en_AU" \
    WP_SITE_HOME="" \
    WP_SITE_PROTOCOL="https" \
    WP_SITE_URL="" \
    WP_TITLE="planet4/wordpress" \
    WP_VERSION="latest"
