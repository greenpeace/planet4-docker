#!/usr/bin/env bash
set -e

dockerize -template /app/wp-config.php.tmpl:/app/source/public/wp-config.php
