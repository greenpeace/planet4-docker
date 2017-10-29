#!/usr/bin/env bash

# Description: Wraps Composer to provide correct user permissions
# Author:      Raymond Walker <raymond.walker@greenpeace.org>


exec setuser ${APP_USER:-$DEFAULT_APP_USER} php /app/bin/composer.phar "$@"
