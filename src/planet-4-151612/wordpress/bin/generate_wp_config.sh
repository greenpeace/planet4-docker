#!/usr/bin/env bash
set -ex

dockerize -template /app/wp-config.php.tmpl:/app/www/wp-config.php
