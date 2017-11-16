#!/usr/bin/env bash
set -e

NGINX_FASTCGI_BACKEND=${NGINX_FASTCGI_BACKEND:-${DEFAULT_NGINX_FASTCGI_BACKEND}}
export NGINX_FASTCGI_BACKEND

dockerize -template /app/templates/etc/nginx/server.d/00_php.conf.tmpl:/etc/nginx/server.d/00_php.conf

dockerize -template /app/templates/etc/nginx/sites-enabled/upstream.conf.tmpl:/etc/nginx/sites-enabled/upstream.conf

if [[ ${PHP_ENABLED} = 'true' ]]
then
  _good "$(printf "%-10s " "nginx:")" "PHP enabled"
  _good "$(printf "%-10s " "nginx:")" "fastcgi_backend=${NGINX_FASTCGI_BACKEND}"

  # Mostly used for testing
  if [[ ! -f "/app/www/index.php" ]]
  then
    echo -e "<?php //TEST-DATA-ONLY\nphpinfo();" > /app/www/index.php
  fi

fi

# Reload configuration if running
if [[ $(pgrep nginx > /dev/null 2>&1) ]]
then
  _good "$(printf "%-10s " "nginx:")" "Reloading configuration ..."
  sv reload nginx
fi
