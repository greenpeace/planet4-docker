#!/usr/bin/env bash
set -e

# Resets database options to environment variable, such as:
# siteurl, home, blogname etc
[[ ${WP_SET_OPTIONS_ON_BOOT} = "true" ]] && /app/bin/set_wp_options.sh

if [[ ${WP_REDIS_ENABLED} = "true" ]]
then
  # Install WP-Redis object cache file if exist
  [[ -f /app/source/public/wp-content/plugins/wp-redis/object-cache.php ]] && wp redis enable
else
  [[ -f /app/source/public/wp-content/object-cache.php ]] && rm -f /app/source/public/wp-content/object-cache.php
fi

/app/bin/generate_wp_config.sh
