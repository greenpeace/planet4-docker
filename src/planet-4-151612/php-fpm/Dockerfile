# Greenpeace P4 Docker application
# Image: gcr.io/planet-4-151612/php-fpm:develop
# Build: build-620
# Date:  Tue May  8 05:31:11 UTC 2018
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------
  
FROM gcr.io/planet-4-151612/ubuntu:develop

LABEL authors="Raymond Walker <raymond.walker@greenpeace.org>"

RUN wget --retry-connrefused --waitretry=1 -t 5 -O - https://download.newrelic.com/548C16BF.gpg | apt-key add - && \
    echo "deb http://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list && \
    apt-get update && \
    apt-get -y --no-install-recommends install \
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
      ssmtp \
      && \
    newrelic-install install && \
  	apt-get clean && \
    rm -Rf /tmp/* /var/tmp/* /var/lib/apt/lists/* && \
    rm -fr /usr/share/man/* /usr/share/doc/* /usr/share/locale/*

ENV \
    ADMIN_EMAIL="nobody@example.com" \
    CHOWN_APP_DIR="false" \
    COMPOSER_HOME="/app/.composer" \
    COMPOSER_PROCESS_TIMEOUT="600" \
    NEWRELIC_APPNAME="Greenpeace P4 Docker application" \
    NEWRELIC_ENABLED="true" \
    NEWRELIC_LICENSE="" \
    PHP_CLEAR_ENV="yes" \
    PHP_DISABLE_FUNCTIONS="" \
    PHP_HEALTH_CHECK_PATH="/health-check" \
    PHP_HEALTH_CHECK_RESPONSE="ok" \
    PHP_MAJOR_VERSION="7.0" \
    PHP_MAX_EXECUTION_TIME="300" \
    PHP_MAX_INPUT_VARS="2000" \
    PHP_MEMORY_LIMIT="128M" \
    PHP_PROCESS_MANAGER_MAX_CHILDREN="10" \
    PHP_PROCESS_MANAGER_MAX_REQUESTS="10000" \
    PHP_PROCESS_MANAGER_MAX_SPARE_SERVERS="3" \
    PHP_PROCESS_MANAGER_MIN_SPARE_SERVERS="2" \
    PHP_PROCESS_MANAGER_START_SERVERS="3" \
    PHP_PROCESS_MANAGER="dynamic" \
    PHP_SESSION_SAVE_HANDLER="files" \
    PHP_SESSION_SAVE_PATH="/var/lib/php/sessions" \
    SOURCE_PATH="/app/source" \
    PUBLIC_PATH="/app/source/public" \
    SSMTP_MAIL_RELAY="smtp" \
    UPLOAD_MAX_SIZE="50M"

EXPOSE 9000

COPY . /app/

RUN chmod 750 /app/bin/* && \
    sync && \
    /app/bin/init_php.sh && \
    /app/bin/php_install_composer.sh
