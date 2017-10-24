# Greenpeace P4 Docker application
# Build: build-104
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------

FROM gcr.io/planet-4-151612/nginx-php-exim:master

MAINTAINER Raymond Walker <raymond.walker@greenpeace.org>

RUN apt-get update && \
    apt-get install -y --no-install-recommends rsync git mysql-client && \
    apt-get clean && \
    rm -Rf /tmp/* /var/tmp/* /var/lib/apt/lists/* && \
    git config --system url."https://".insteadOf "git://" && \
    # composer config --global github-protocols https && \
    curl -o /app/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    wget https://github.com/jwilder/dockerize/releases/download/v0.5.0/dockerize-linux-amd64-v0.5.0.tar.gz && \
    tar -C /usr/local/bin -xzvf dockerize-linux-amd64-v0.5.0.tar.gz && \
    rm dockerize-linux-amd64-v0.5.0.tar.gz

COPY . /app/

WORKDIR /app

RUN rm -fr /app/www && mkdir /app/www && \
    cp -R etc/* /etc/ && \
    chmod +x /etc/my_init.d/*.sh && \
    chmod +x /app/bin/*.sh && \
    cp bin/wp.sh /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

# See https://hub.docker.com/r/greenpeace/nginx-php-exim/
ENV PHP_CLEAR_ENV no

ENV WP_TITLE "planet4/wordpress"
ENV WP_HOSTNAME ""
ENV WP_SITE_URL ""
ENV WP_SITE_HOME ""
ENV WP_SITE_PROTOCOL "https"
ENV WP_DB_HOST "db"
ENV WP_DB_PORT "3306"
ENV WP_DB_NAME ""
ENV WP_DB_USER ""
ENV WP_DB_PASS ""
ENV WP_DB_PREFIX "wp_"
ENV WP_DB_CHARSET "utf8"
ENV WP_DB_COLLATION ""
ENV WP_FORCE_SSL_ADMIN "false"
ENV WP_ADMIN_NAME ""
ENV WP_ADMIN_USER ""
ENV WP_ADMIN_PASS ""
ENV WP_ADMIN_EMAIL ""
ENV WP_VERSION "latest"
ENV WP_LOCALE "en_AU"
ENV OVERWRITE_FILES "false"
