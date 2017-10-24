#!/usr/bin/env bash
set -e

# Find updated scripts at:
# https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md

retries=5

EXPECTED_SIGNATURE=$(wget --retry-connrefused --waitretry=1 -t $retries -q -O - https://composer.github.io/installer.sig)

loop=$retries
until php -r "copy('http://getcomposer.org/installer', 'composer-setup.php');"
do
  loop=$((loop - 1))
  if [[ loop -lt 1 ]]
  then
    >&2 echo "Failed to download composer after $retries attempts"
    exit 1
  fi
  sleep 1
done

ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
then
    >&2 echo 'ERROR: Invalid installer signature'
    rm composer-setup.php
    exit 1
fi

# php composer-setup.php --quiet
php composer-setup.php --install-dir=/app/bin
RESULT=$?
rm composer-setup.php

/app/bin/composer.phar --no-plugins --no-scripts --profile -vvv global require hirak/prestissimo

exit $RESULT
