#!/bin/bash
set -eou pipefail

mkdir -p /run/php

# Backup original information
cp "/etc/php/${PHP_MAJOR_VERSION}/fpm/php.ini" "/etc/php/${PHP_MAJOR_VERSION}/fpm/php.ini.dist"
cp "/etc/php/${PHP_MAJOR_VERSION}/fpm/pool.d/www.conf" "/etc/php/${PHP_MAJOR_VERSION}/fpm/pool.d/www.conf.dist"

# Don't fork
sed -i -r "s/;daemonize = yes/daemonize = no/g" "/etc/php/${PHP_MAJOR_VERSION}/fpm/php-fpm.conf"

# Clear upstream data
rm -fr "${PUBLIC_PATH}" || true

mkdir -p "${PUBLIC_PATH}"

# Create a test PHP index file if it doesn't exist
[[ -f "${PUBLIC_PATH}/index.php" ]] || {
  cat <<EOF >"${PUBLIC_PATH}/index.php"
<?php
//TEST-DATA-ONLY
phpinfo();

EOF
}
