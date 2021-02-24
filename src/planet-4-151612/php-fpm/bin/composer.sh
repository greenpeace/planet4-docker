#!/usr/bin/env bash
set -e

# Description: Wraps Composer to provide correct user permissions
# Author:      Raymond Walker <raymond.walker@greenpeace.org>

uid=$(id -u)

if [[ $uid = "0" ]]; then
  if [[ $(ls -ld "${SOURCE_PATH}" | awk '{print $3}') != "${APP_USER}" ]]; then
    chown -R ${APP_USER} /app/.composer
    # Find dirs/files *not* owned by APP_USER, and pipe them one by one to chown
    [[ -e "${SOURCE_PATH}" ]] && find "${SOURCE_PATH}" ! -user ${APP_USER} -exec chown -f ${APP_USER} {} \;
  fi
  exec setuser ${APP_USER} php /app/bin/composer.phar "$@"
elif [[ $uid = "${APP_UID}" ]]; then
  php /app/bin/composer.phar "$@"
else
  echo >&2 "ERROR incorrect user - ${APP_USER} - how did this happen? Please tell an admin!"
  echo >&2 "Expected ${APP_UID}"
  echo >&2 "Got      ${uid}"
  exit 1
fi
