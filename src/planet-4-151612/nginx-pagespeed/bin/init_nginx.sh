#!/bin/sh
set -e

cp -R /app/etc/* /etc

chmod +x /etc/service/*/run

ln -s /app/bin/add_user.sh /etc/my_init.d/00_add_user.sh

mkdir -p /etc/nginx/ssl

mkdir -p /app/www

BUILD_DATE=$(date)

echo "<html><head>Success</head><body><p><a href=\"https://hub.docker.com/u/greenpeace/\">greenpeace</a>/nginx:${NGINX_VERSION}-${OPENSSL_VERSION} - ${BUILD_DATE}</p>" > /app/www/index.html
