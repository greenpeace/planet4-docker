#!/usr/bin/env bash
set -e

dockerize -template /app/templates/etc/nginx/server.d/00_php.conf.tmpl:/etc/nginx/server.d/00_php.conf

dockerize -template /app/templates/etc/nginx/sites-enabled/upstream.conf.tmpl:/etc/nginx/sites-enabled/upstream.conf

[[ ${PHP_ENABLED} = 'true' ]] && _good "$(printf "%-10s " "nginx:")" "fastcgi_backend=${NGINX_FASTCGI_BACKEND:${DEFAULT_NGINX_FASTCGI_BACKEND}} "

# Reload configuration if running
if [[ $(pgrep nginx > /dev/null 2>&1) ]]
then
  _good "$(printf "%-10s " "nginx:")" "Reloading configuration ..."
  sv reload nginx
fi
