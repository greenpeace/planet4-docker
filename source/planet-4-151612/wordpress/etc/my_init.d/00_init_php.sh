#!/usr/bin/env bash
# =============================================================================
# 	PHP-FPM
# =============================================================================

# Ubuntu xenial php doesn't create /run/php, where it expects socket files to live
chown -R ${APP_USER:-$DEFAULT_APP_USER} /run/php

# replace PHP upstream
_good "nginx:    upstream  ${NGINX_FASTCGI_BACKEND:-$DEFAULT_NGINX_FASTCGI_BACKEND}"
sed -i -r "s#server:.*;#server: ${NGINX_FASTCGI_BACKEND:-$DEFAULT_NGINX_FASTCGI_BACKEND};#g" /etc/nginx/sites-enabled/upstream.conf

# replace PHP Pool name
POOL_NAME=`echo ${APP_HOSTNAME} | sed -e 's/[^a-zA-Z]/_/g'`
_good "php:    pool name   ${POOL_NAME}"
sed -i -r "s/^\[.*\]$/\[${POOL_NAME}\]/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# set php-fpm user to match nginx
_good "php:    user:  ${APP_USER:-$DEFAULT_APP_USER}"
_good "php:    group: ${APP_GROUP:-$DEFAULT_APP_GROUP}"
sed -i -r "s/^user\s*=.+$/user = ${APP_USER:-$DEFAULT_APP_USER}/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sed -i -r "s/^group\s*=.+$/group = ${APP_GROUP:-$DEFAULT_APP_GROUP}/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sed -i -r "s/^listen.owner\s*=.+$/listen.owner = ${APP_USER:-$DEFAULT_APP_USER}/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sed -i -r "s/^listen.group\s*=.+$/listen.group = ${APP_GROUP:-$DEFAULT_APP_GROUP}/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf


# memory limit
_good "php:    memory_limit:         ${PHP_MEMORY_LIMIT:-$DEFAULT_PHP_MEMORY_LIMIT}"
sed -i -r "s/^.*memory_limit\s*=\s*[0-9]+[MG]/memory_limit = ${PHP_MEMORY_LIMIT:-$DEFAULT_PHP_MEMORY_LIMIT}/g" /etc/php/${PHP_VERSION}/fpm/php.ini

# file upload limits
_good "php:    upload_max_filesize:  ${UPLOAD_MAX_SIZE:-$DEFAULT_UPLOAD_MAX_SIZE}"
_good "php:    post_max_size:        ${UPLOAD_MAX_SIZE:-$DEFAULT_UPLOAD_MAX_SIZE}"
sed -i -r "s/^.*upload_max_filesize\s*=\s*[0-9]+M/upload_max_filesize = ${UPLOAD_MAX_SIZE:-$DEFAULT_UPLOAD_MAX_SIZE}/g" /etc/php/${PHP_VERSION}/fpm/php.ini
sed -i -r "s/^.*post_max_size\s*=\s*[0-9]+M/post_max_size = ${UPLOAD_MAX_SIZE:-$DEFAULT_UPLOAD_MAX_SIZE}/g" /etc/php/${PHP_VERSION}/fpm/php.ini

# maximum execution time
_good "php:    max_execution_time:   ${PHP_MAX_EXECUTION_TIME:-$DEFAULT_PHP_MAX_EXECUTION_TIME}"
sed -i -r "s/^.*max_execution_time\s*=.*$/max_execution_time = ${PHP_MAX_EXECUTION_TIME:-$DEFAULT_PHP_MAX_EXECUTION_TIME}/g" /etc/php/${PHP_VERSION}/fpm/php.ini

# maximum input variables
_good "php:    max_input_vars:       ${PHP_MAX_INPUT_VARS:-$DEFAULT_PHP_MAX_INPUT_VARS}"
sed -i -r "s/^.*max_input_vars\s*=.*$/max_input_vars = ${PHP_MAX_INPUT_VARS:-$DEFAULT_PHP_MAX_INPUT_VARS}/g" /etc/php/${PHP_VERSION}/fpm/php.ini

# expose environment variables
_good "php:    clear_env:            ${PHP_CLEAR_ENV:-$DEFAULT_PHP_CLEAR_ENV}"
sed -i -r "s/^.*clear_env\s*=.*$/clear_env = ${PHP_CLEAR_ENV:-$DEFAULT_PHP_CLEAR_ENV}/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# php process manager
_good "php:    pm.max_children:      ${PHP_MAX_CHILDREN:-$DEFAULT_PHP_MAX_CHILDREN}"
_good "php:    pm.start_servers:     ${PHP_START_SERVERS:-$DEFAULT_PHP_START_SERVERS}"
_good "php:    pm.min_spare_servers: ${PHP_MIN_SPARE_SERVERS:-$DEFAULT_PHP_MIN_SPARE_SERVERS}"
_good "php:    pm.max_spare_servers: ${PHP_MAX_SPARE_SERVERS:-$DEFAULT_PHP_MAX_SPARE_SERVERS}"
_good "php:    pm.max_requests:      ${PHP_MAX_REQUESTS:-$DEFAULT_PHP_MAX_REQUESTS}"
sed -i -r "s/pm = \w+\s*=\s*[0-9]+/pm = ${PHP_PROCESS_MANAGER:-$DEFAULT_PHP_PROCESS_MANAGER}/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sed -i -r "s/pm.max_children\s*=\s*[0-9]+/pm.max_children = ${PHP_MAX_CHILDREN:-$DEFAULT_PHP_MAX_CHILDREN}/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sed -i -r "s/pm.start_servers\s*=\s*[0-9]+/pm.start_servers = ${PHP_START_SERVERS:-$DEFAULT_PHP_START_SERVERS}/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sed -i -r "s/pm.min_spare_servers\s*=\s*[0-9]+/pm.min_spare_servers =  ${PHP_MIN_SPARE_SERVERS:-$DEFAULT_PHP_MIN_SPARE_SERVERS}/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sed -i -r "s/pm.max_spare_servers\s*=\s*[0-9]+/pm.max_spare_servers = ${PHP_MAX_SPARE_SERVERS:-$DEFAULT_PHP_MAX_SPARE_SERVERS}/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sed -i -r "s/pm.max_requests\s*=\s*[0-9]+/pm.max_requests = ${PHP_MAX_REQUESTS:-$DEFAULT_PHP_MAX_REQUESTS}/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# disable_functions
DIST_DISABLE_FUNCTIONS=`grep "disable_functions =" /etc/php/${PHP_VERSION}/fpm/php.ini.dist`
if [[ "${PHP_DISABLE_FUNCTIONS:-$DEFAULT_PHP_DISABLE_FUNCTIONS}" != "false" ]]; then
    _good "php:    disable_functions:    ${PHP_DISABLE_FUNCTIONS:-$DEFAULT_PHP_DISABLE_FUNCTIONS}"
    sed -i -r "s/^disable_functions =.*$/${DIST_DISABLE_FUNCTIONS}${PHP_DISABLE_FUNCTIONS:-$DEFAULT_PHP_DISABLE_FUNCTIONS}/g" /etc/php/${PHP_VERSION}/fpm/php.ini
fi


# newrelic
if [[ "${NEWRELIC_ENABLED:-$DEFAULT_NEWRELIC_ENABLED}" == "false" ]] || [[ "${NEWRELIC_LICENSE:-$DEFAULT_NEWRELIC_LICENSE}" =~ "DISABLED" ]]; then
    _good "php:    newrelic.enabled:     false"
    sed -i -r "s/newrelic.enabled =$/newrelic.enabled = false/g" /etc/php/${PHP_VERSION}/fpm/conf.d/20-newrelic.ini
    phpdismod newrelic
    NEWRELIC_ENABLED=false
else
    _good "php:    newrelic.enabled:     true"
    _good "php:    newrelic.appname:     ${NEWRELIC_APPNAME:-$POOL_NAME}"
    _good "php:    newrelic.license:     ${NEWRELIC_LICENSE:-$DEFAULT_NEWRELIC_LICENSE}"
    sed -i -r "s/newrelic.enabled\s=.*$/newrelic.enabled = true/g" /etc/php/${PHP_VERSION}/fpm/conf.d/20-newrelic.ini
    sed -i -r "s/newrelic.appname\s=.*$/newrelic.appname = \"${NEWRELIC_APPNAME:-$POOL_NAME}\"/g" /etc/php/${PHP_VERSION}/fpm/conf.d/20-newrelic.ini
    sed -i -r "s/newrelic.license\s=.*$/newrelic.license=\"${NEWRELIC_LICENSE:-$DEFAULT_NEWRELIC_LICENSE}\"/g" /etc/php/${PHP_VERSION}/fpm/conf.d/20-newrelic.ini
    phpenmod newrelic
    NEWRELIC_ENABLED=true
fi

# xdebug
if [[ "$NEWRELIC_ENABLED" != "true" ]] && [[ "${APP_ENV:-$DEFAULT_APP_ENV}" == "development" ]]; then
    _good "php:    xdebug.remote_host:   ${PHP_XDEBUG_REMOTE_HOST:-$DEFAULT_PHP_XDEBUG_REMOTE_HOST}"
    _good "php:    xdebug.remote_port:   ${PHP_XDEBUG_REMOTE_PORT:-$DEFAULT_PHP_XDEBUG_REMOTE_PORT}"
    _good "php:    xdebug.ide_key:       ${PHP_XDEBUG_IDE_KEY:-$DEFAULT_PHP_XDEBUG_IDE_KEY}"
	sed -i -r "s/^xdebug.remote_enable=0$/xdebug.remote_enable=1/g" /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
	sed -i -r "s/^xdebug.remote_autostart=0$/xdebug.remote_autostart=1/g" /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
	sed -i -r "s/^xdebug.profiler_enable_trigger=0$/xdebug.profiler_enable_trigger=1/g" /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
	sed -i -r "s/^xdebug.remote_host=.+$/xdebug.remote_host=${PHP_XDEBUG_REMOTE_HOST:-$DEFAULT_PHP_XDEBUG_REMOTE_HOST}/g" /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
	sed -i -r "s/^xdebug.remote_port=.+$/xdebug.remote_port=${PHP_XDEBUG_REMOTE_PORT:-$DEFAULT_PHP_XDEBUG_REMOTE_PORT}/g" /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
	sed -i -r "s/^xdebug.ide_key=.+$/xdebug.ide_key=${PHP_XDEBUG_IDE_KEY:-$DEFAULT_PHP_XDEBUG_IDE_KEY}/g" /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
	chown -R ${APP_USER:-$DEFAULT_APP_USER}:${APP_USER:-$DEFAULT_APP_USER} /app/xdebug
	phpenmod xdebug
else
    sed -i -r "s/^xdebug.remote_enable=1$/xdebug.remote_enable=0/g" /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
	sed -i -r "s/^xdebug.profiler_enable_trigger=1$/xdebug.profiler_enable_trigger=0/g" /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
    phpdismod xdebug
fi

if [[ "${EXIM_MAIL_FROM:-$DEFAULT_EXIM_MAIL_FROM}" == "example.com" ]]; then
	# _good "exim:   mail_from ${APP_HOSTNAME}"
	EXIM_MAIL_FROM=${APP_HOSTNAME:-${VIRTUAL_HOST:-$(hostname)}}
fi

# sendmail parameters
_good "php:    sendmail_path:         /usr/bin/sendmail -t -f no-reply@${EXIM_MAIL_FROM:-$DEFAULT_EXIM_MAIL_FROM}"
sed -i -r "s/sendmail_path =.*$/sendmail_path = \/usr\/sbin\/sendmail -t -f no-reply@${EXIM_MAIL_FROM:-$DEFAULT_EXIM_MAIL_FROM}/g" /etc/php/${PHP_VERSION}/fpm/php.ini
