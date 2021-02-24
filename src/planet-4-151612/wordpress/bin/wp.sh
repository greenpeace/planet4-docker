#!/usr/bin/env bash
set -e

# Description: Wraps wp-cli to provide correct user permissions
# Author:      Raymond Walker <raymond.walker@greenpeace.org>

# Configure environment
for env_file in /app/env/*; do
  . "${env_file}"
done

uid=$(id -u)

if [[ $uid = "0" ]]; then
  if [[ $1 = "--root" ]]; then
    shift
    php /app/wp-cli.phar --allow-root --path="${PUBLIC_PATH}" "$@"
  else
    setuser "${APP_USER}" php /app/wp-cli.phar --path="${PUBLIC_PATH}" "$@"
  fi
elif [[ $uid = "${APP_UID}" ]]; then
  php /app/wp-cli.phar --path="${PUBLIC_PATH}" "$@"
else
  echo >&2 "ERROR incorrect user - ${APP_USER} - how did this happen? Please tell an admin!"
  echo >&2 "Expected ${APP_UID}"
  echo >&2 "Got      ${uid}"
  exit 1
fi
