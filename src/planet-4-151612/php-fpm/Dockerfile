# Greenpeace P4 Docker application
# Image: gcr.io/planet-4-151612/php-fpm:feature-php
# Build: build-238
# Date:  Tue Nov 14 23:10:32 UTC 2017
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------

FROM gcr.io/planet-4-151612/ubuntu:feature-php

MAINTAINER Ray Walker <hello@raywalker.it>

RUN wget --retry-connrefused --waitretry=1 -t 5 -O - https://download.newrelic.com/548C16BF.gpg | apt-key add - && \
    echo "deb http://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list && \
    apt-get update && \
    apt-get -y --no-install-recommends install \
		  exim4 \
	    newrelic-php5 \
  		php \
  		php-cli \
  		php-curl \
  		php-gd \
  		php-imagick \
  		php-imap \
  		php-mcrypt \
  		php-xml \
  		php-xsl \
  		php-zip \
      php-fpm \
      php-intl \
      php-mbstring \
      php-memcache \
      php-memcached \
      php-mysql \
      php-recode \
      php-redis \
      php-soap \
      && \
    newrelic-install install && \
  	apt-get clean && \
    rm -Rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

ENV \
    COMPOSER_HOME="/app/.composer" \
    DEFAULT_ADMIN_EMAIL="nobody@example.com" \
    DEFAULT_CHOWN_APP_DIR="false" \
    DEFAULT_EXIM_DELIVERY_MODE="local" \
    DEFAULT_EXIM_MAIL_FROM="example.com" \
    DEFAULT_EXIM_SMARTHOST_AUTH_PASSWORD="password_123" \
    DEFAULT_EXIM_SMARTHOST_AUTH_USERNAME="postmaster@example.com" \
    DEFAULT_EXIM_SMARTHOST="smtp.example.org::587" \
    DEFAULT_NEWRELIC_APPNAME="${APPLICATION_NAME}" \
    DEFAULT_NEWRELIC_ENABLED="false" \
    DEFAULT_PHP_CLEAR_ENV="yes" \
    DEFAULT_PHP_DISABLE_FUNCTIONS="" \
    DEFAULT_PHP_HEALTH_CHECK_PATH="/health-check" \
    DEFAULT_PHP_HEALTH_CHECK_RESPONSE="ok" \
    DEFAULT_PHP_MAX_EXECUTION_TIME="300" \
    DEFAULT_PHP_MAX_INPUT_VARS="2000" \
    DEFAULT_PHP_MEMORY_LIMIT="128M" \
    DEFAULT_PHP_PROCESS_MANAGER_MAX_CHILDREN="6" \
    DEFAULT_PHP_PROCESS_MANAGER_MAX_REQUESTS="500" \
    DEFAULT_PHP_PROCESS_MANAGER_MAX_SPARE_SERVERS="3" \
    DEFAULT_PHP_PROCESS_MANAGER_MIN_SPARE_SERVERS="2" \
    DEFAULT_PHP_PROCESS_MANAGER_START_SERVERS="3" \
    DEFAULT_PHP_PROCESS_MANAGER="dynamic" \
    DEFAULT_UPLOAD_MAX_SIZE="50M" \
    DEFAULT_VIRTUAL_HOST="example.com" \
    NEWRELIC_LICENSE="" \
    PHP_MAJOR_VERSION="7.0"

EXPOSE 9000

COPY . /app/

RUN chmod 750 /app/bin/* && \
    sync && \
    /app/bin/init_php.sh && \
    /app/bin/php_install_composer.sh
