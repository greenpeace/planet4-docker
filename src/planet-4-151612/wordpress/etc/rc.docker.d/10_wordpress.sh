#!/usr/bin/env bash
set -e

[[ ${WP_SET_OPTIONS_ON_BOOT} = "true" ]] && /app/bin/set_wp_options.sh

# Install WP-Redis object cache file if exist
# FIXME there must be a better way
if [[ ${WP_REDIS_ENABLED} = "true" ]]
then
  [[ -f /app/source/public/wp-content/plugins/wp-redis/object-cache.php ]] && wp redis enable
else
  [[ -f /app/source/public/wp-content/object-cache.php ]] && rm -f /app/source/public/wp-content/object-cache.php
fi

/app/bin/generate_wp_config.sh
