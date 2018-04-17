#!/usr/bin/env bash
set -ex

dockerize -template "/app/wp-config.php.tmpl:${PUBLIC_PATH}/wp-config.php"
