#!/usr/bin/env bash
set -ea

PHP_POOL_NAME=${APP_HOSTNAME//[^[:alnum:]_]/_}

export PHP_POOL_NAME
