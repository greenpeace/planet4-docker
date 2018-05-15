# Greenpeace P4 Docker application
# Image: gcr.io/planet-4-151612/wordpress:v0.9.0
# Build: build-678
# Date:  Tue May 15 10:11:26 UTC 2018
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------
  
FROM gcr.io/planet-4-151612/php-fpm:v0.9.0

LABEL authors="Raymond Walker <raymond.walker@greenpeace.org>"

RUN apt-get update && \
    apt-get install -y --no-install-recommends rsync git mysql-client && \
    apt-get clean && \
    rm -Rf /tmp/* /var/tmp/* /var/lib/apt/lists/* && \
    curl --retry 5 -o /app/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    ln -s /app/bin/wp.sh /app/bin/wp && \
    mkdir -p "/app/source"

COPY . /app/

WORKDIR /app/source

ENV \
    GIT_REF="master" \
    GIT_SOURCE="https://github.com/greenpeace/planet4-base" \
    INSTALL_WORDPRESS="true" \
    MERGE_REF="" \
    MERGE_SOURCE="" \
    OVERWRITE_FILES="false" \
    PHP_CLEAR_ENV="yes" \
    WP_ADMIN_EMAIL="raymond.walker@greenpeace.org" \
    WP_ADMIN_NAME="" \
    WP_ADMIN_PASS="" \
    WP_ADMIN_USER="" \
    WP_AUTH_KEY="" \
    WP_AUTH_SALT="" \
    WP_AUTO_UPDATE_CORE="false" \
    WP_AUTOMATIC_UPDATER_DISABLED="true" \
    WP_BAKE="false" \
    WP_CLI_CACHE_DIR="/app/.wp-cli/cache" \
    WP_CLI_DISABLE_AUTO_CHECK_UPDATE="true" \
    WP_DB_CHARSET="utf8" \
    WP_DB_COLLATION="" \
    WP_DB_HOST="db" \
    WP_DB_NAME="" \
    WP_DB_PASS="" \
    WP_DB_PORT="3306" \
    WP_DB_PREFIX="wp_" \
    WP_DB_USER="" \
    WP_DEFAULT_CONTENT="true" \
    WP_DESCRIPTION="Greenpeace" \
    WP_EXTRA_CONFIG="" \
    WP_FORCE_SSL_ADMIN="false" \
    WP_HOSTNAME="" \
    WP_LOCALE="en_AU" \
    WP_LOGGED_IN_KEY="" \
    WP_LOGGED_IN_SALT="" \
    WP_NONCE_KEY="" \
    WP_NONCE_SALT="" \
    WP_REDIS_ENABLED="false" \
    WP_REDIS_HOST="redis" \
    WP_REDIS_PORT="6379" \
    WP_REDIS_DB="0" \
    WP_REWRITE_STRUCTURE="/%category%/%post_id%/%postname%/" \
    WP_SECURE_AUTH_KEY="" \
    WP_SECURE_AUTH_SALT="" \
    WP_SET_OPTIONS_ON_BOOT="true" \
    WP_SITE_HOME="" \
    WP_SITE_PROTOCOL="https" \
    WP_SITE_URL="" \
    WP_STATELESS_MEDIA_BUCKET="" \
    WP_STATELESS_MEDIA_ENABLED="" \
    WP_STATELESS_MEDIA_JSON_KEY="" \
    WP_STATELESS_MEDIA_KEY_FILE_PATH="" \
    WP_STATELESS_MEDIA_MODE="stateless" \
    WP_STATELESS_MEDIA_ROOT_DIR="" \
    WP_STATELESS_MEDIA_SERVICE_ACCOUNT="" \
    WP_THEME="planet4-master-theme" \
    WP_TITLE="Greenpeace" \
    WP_VERSION="latest"
