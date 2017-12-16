#!/usr/bin/env bash
set -e

# FIXME Re-apply wordpress configuration options at container start to override
# wp-config.php values

[[ ${WP_SET_OPTIONS_ON_BOOT} == "true" ]] && /app/bin/set_wp_options.sh

dockerize -template /app/wp-config.php.tmpl:/app/source/public/wp-config.php
