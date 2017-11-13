#!/bin/bash
set -eou pipefail

mkdir -p /run/php

# Backup original information
cp /etc/php/${PHP_MAJOR_VERSION}/fpm/php.ini /etc/php/${PHP_MAJOR_VERSION}/fpm/php.ini.dist
cp /etc/php/${PHP_MAJOR_VERSION}/fpm/pool.d/www.conf /etc/php/${PHP_MAJOR_VERSION}/fpm/pool.d/www.conf.dist

# Remove duplicate newrelic.ini files. Solves "Module 'newrelic' already loaded" warning message
# See: https://discuss.newrelic.com/t/php-warning-module-newrelic-already-loaded-in-unknown-on-line-0/2903/21
rm -f /etc/php/${PHP_MAJOR_VERSION}/fpm/conf.d/newrelic.ini
rm -f /etc/php/${PHP_MAJOR_VERSION}/cli/conf.d/newrelic.ini

# Don't fork
sed -i -r "s/;daemonize = yes/daemonize = no/g" /etc/php/${PHP_MAJOR_VERSION}/fpm/php-fpm.conf

# Clear upstream data
rm -fr /app/www
mkdir -p /app/www
echo "<?php phpinfo(); " > /app/www/index.php
