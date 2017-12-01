#!/usr/bin/env bash
set -e

# Description: Wraps Composer to provide correct user permissions
# Author:      Raymond Walker <raymond.walker@greenpeace.org>

uid=$(id -u)

if [[ $uid = "0" ]]
then
  if [[ $(ls -ldn . | awk '{print $3}') != "${APP_USER:-$DEFAULT_APP_USER}" ]]
  then
    chown -R ${APP_USER:-$DEFAULT_APP_USER} /app/.composer
    chown -R ${APP_USER:-$DEFAULT_APP_USER} /app/source
  fi
  exec setuser ${APP_USER:-$DEFAULT_APP_USER} php /app/bin/composer.phar "$@"
elif [[ $uid = "${APP_UID:-${DEFAULT_APP_UID}}" ]]
then
  php /app/bin/composer.phar "$@"
else
  >&2 echo "ERROR incorrect user - ${APP_USER:-$DEFAULT_APP_USER} - how did this happen? Please tell an admin!"
  >&2 echo "Expected ${APP_UID:-${DEFAULT_APP_UID}}"
  >&2 echo "Got      ${uid}"
  exit 1
fi
