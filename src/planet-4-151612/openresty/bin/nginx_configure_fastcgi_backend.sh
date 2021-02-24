#!/usr/bin/env bash
set -e

OPENRESTY_FASTCGI_BACKEND=${OPENRESTY_FASTCGI_BACKEND}
export OPENRESTY_FASTCGI_BACKEND

dockerize -template /app/templates/etc/nginx/server.d/10_php.conf.tmpl:/etc/nginx/server.d/10_php.conf

dockerize -template /app/templates/etc/nginx/sites-enabled/upstream.conf.tmpl:/etc/nginx/sites-enabled/upstream.conf

if [[ ${PHP_ENABLED} = 'true' ]]; then
  _good "$(printf "%-10s " "openresty:")" "PHP enabled"
  _good "$(printf "%-10s " "openresty:")" "fastcgi_backend=${OPENRESTY_FASTCGI_BACKEND}"

  # Mostly used for testing
  if [[ ! -f "${PUBLIC_PATH}/index.php" ]]; then
    echo -e "<?php //TEST-DATA-ONLY\nphpinfo();" >"${PUBLIC_PATH}/index.php"
  fi

fi

# Reload configuration if running
if [[ $(pgrep nginx >/dev/null 2>&1) ]]; then
  _good "$(printf "%-10s " "openresty:")" "Reloading configuration ..."
  sv reload nginx
fi
