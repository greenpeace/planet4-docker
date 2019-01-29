#!/usr/bin/env bash
set -e

# Description: Install composer from latest source
# Author: Raymond Walker <raymond.walker@greenpeace.org>
# https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
# Modified from original script to:
#  - fail on any script errors
#  - retry connection failures using wget

retries=5

EXPECTED_SIGNATURE=$(wget --retry-connrefused --waitretry=1 -t $retries -q -O - https://composer.github.io/installer.sig)

wget --retry-connrefused --waitretry=1 -t $retries -O composer-setup.php http://getcomposer.org/installer
ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
then
  >&2 echo 'ERROR: Invalid installer signature'
  exit 1
fi

# Installs composer.phar to /app/bin/composer.phar
# Available on path, wrapped by /app/bin/composer.sh, symlinked to /app/bin/composer
php composer-setup.php --version="$COMPOSER_VERSION" --install-dir=/app/bin
rm composer-setup.php

ln -s /app/bin/composer.sh /app/bin/composer

echo "Clearing composer cache"
/app/bin/composer.phar clear-cache
