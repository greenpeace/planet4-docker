#!/usr/bin/env bash
set -ex

exec setuser ${APP_USER:-$DEFAULT_APP_USER} php /app/wp-cli.phar --verbose --path="/app/source/public" "$@"
