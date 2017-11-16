#!/usr/bin/env bash

# Description: Wraps Composer to provide correct user permissions
# Author:      Raymond Walker <raymond.walker@greenpeace.org>

if [[ $(stat -c "%U" "${COMPOSER_HOME}") != "${APP_USER:-$DEFAULT_APP_USER}" ]] || [[ "$(stat -c "%U" /app/.composer)" != "${APP_GROUP:-$DEFAULT_APP_GROUP}" ]]
then
  chown -R ${APP_USER:-$DEFAULT_APP_USER}:${APP_GROUP:-$DEFAULT_APP_GROUP} /app
fi

exec setuser ${APP_USER:-$DEFAULT_APP_USER} php /app/bin/composer.phar "$@"
