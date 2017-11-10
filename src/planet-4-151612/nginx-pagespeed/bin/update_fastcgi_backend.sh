#!/usr/bin/env bash
set -e

# replace PHP upstream
_good "nginx:    upstream  ${NGINX_FASTCGI_BACKEND:-$DEFAULT_NGINX_FASTCGI_BACKEND}"
sed -i -r "s#server:.*;#server: ${NGINX_FASTCGI_BACKEND:-$DEFAULT_NGINX_FASTCGI_BACKEND};#g" /etc/nginx/sites-enabled/upstream.conf

# reload configuration if running
sv reload nginx || true
