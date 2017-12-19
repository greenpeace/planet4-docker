#!/usr/bin/env bash
set -e

# Description: Wraps wp-cli to provide correct user permissions
# Author:      Raymond Walker <raymond.walker@greenpeace.org>

# Configure environment
for env_file in /app/env/*
do
  # shellcheck source=/dev/null
  . "${env_file}"
done

uid=$(id -u)

if [[ $uid = "0" ]]
then
  setuser ${APP_USER} php /app/wp-cli.phar --path="/app/source/public" "$@"
elif [[ $uid = "${APP_UID}" ]]
then
  php /app/wp-cli.phar --path="/app/source/public" "$@"
else
  >&2 echo "ERROR incorrect user - ${APP_USER} - how did this happen? Please tell an admin!"
  >&2 echo "Expected ${APP_UID}"
  >&2 echo "Got      ${uid}"
  exit 1
fi
