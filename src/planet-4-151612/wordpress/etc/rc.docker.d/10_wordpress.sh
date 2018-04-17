#!/usr/bin/env bash
set -ex

# Executed after my_init.d

chown -R "$APP_USER:$APP_GROUP" "${PUBLIC_PATH}"

# Generates keys and salts for wp-config.php
/app/bin/generate_wp_keys.sh
/app/bin/generate_wp_config.sh

# Resets database options to environment variable, such as:
# siteurl, home, blogname etc
[[ ${WP_SET_OPTIONS_ON_BOOT} = "true" ]] && /app/bin/set_wp_options.sh

if [[ ${WP_REDIS_ENABLED} = "true" ]]
then
  # Install WP-Redis object cache file if exist
  [[ -f "${PUBLIC_PATH}/wp-content/plugins/wp-redis/object-cache.php" ]] && wp redis enable
else
  [[ -f "${PUBLIC_PATH}/wp-content/object-cache.php" ]] && rm -f "${PUBLIC_PATH}/wp-content/object-cache.php" || true
fi

exit 0
