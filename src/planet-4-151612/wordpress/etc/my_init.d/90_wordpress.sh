#!/usr/bin/env bash
set -euo pipefail

# Executed after my_init.d and environment is established

# Create wp-config.php file, overwrite if not in local environment
if [[ ! -f "${PUBLIC_PATH}/wp-config.php" ]] || [[ "${APP_ENV}" != "local" ]]; then
  # Generates keys and salts for wp-config.php
  /app/bin/generate_wp_keys.sh

  # Write the wp-config.php file from template
  /app/bin/generate_wp_config.sh
fi

# Wait up to two minutes for the database to become ready
timeout=2
i=0
until dockerize -wait "tcp://${WP_DB_HOST}:${WP_DB_PORT}" -timeout 60s mysql -h "${WP_DB_HOST}" -u "${WP_DB_USER}" --password="${WP_DB_PASS}" -e "use ${WP_DB_NAME}"; do
  i=$((i + 1))
  if [[ $i -ge $timeout ]]; then
    _error "Timeout waiting for database to become ready"
    exit 1
  fi
done

if ! wp core is-installed; then
  _good "Installing Wordpress..."
  wp core install --url="${WP_HOSTNAME}" --title="$WP_TITLE" --admin_user="${WP_ADMIN_USER:-admin}" --admin_email="${WP_ADMIN_EMAIL:-$MAINTAINER_EMAIL}"

  _good "Activating plugins..."
  wp plugin activate --all

  # FIXME Determine which theme to activate
  # FIXME Why does the composer theme install script fail?
  _good "Activating theme: ${WP_THEME}"
  wp theme activate "${WP_THEME}"
fi
_good "Wordpress v$(wp core version) installed"

# Resets database options to environment variable, such as:
# siteurl, home, blogname etc
if [[ ${WP_SET_OPTIONS_ON_BOOT} = "true" ]]; then
  /app/bin/set_wp_options.sh
else
  _good "WP_SET_OPTIONS_ON_BOOT is false, skip setting WP options on boot..."
fi

if [[ ${WP_REDIS_ENABLED} = "true" ]]; then
  _good "00 - The WP_REDIS_ENABLED is true"
  # Install WP-Redis object cache file if exist
  [[ -f "${PUBLIC_PATH}/wp-content/plugins/wp-redis/object-cache.php" ]] && {
    _good "Enabling redis object cache ..."
    [[ -e "${PUBLIC_PATH}/wp-content/object-cache.php" ]] || {
      _good " - 01 - Doing the ln -s for the object-cache.php ..."
      ln -s "${PUBLIC_PATH}/wp-content/plugins/wp-redis/object-cache.php" "${PUBLIC_PATH}/wp-content/object-cache.php"
      _good " - 02 - Did the ln -s for the object-cache.php ..."
    }
  }
  _good "Finished WP_REDIS_ENABLED being true"
else
  _good "The WP_REDIS_ENABLED was not true ..."
  if [[ -e "${PUBLIC_PATH}/wp-content/object-cache.php" ]]; then
    _good "Disabling redis object cache ..."
    rm -f "${PUBLIC_PATH}/wp-content/object-cache.php"
  fi
fi

wp plugin activate wordfence
_good "Starting Wordfence WAF rules"
# Wordfence workaround to enable WAF rules immediately instead of waiting for learning period
# See: https://wordpress.org/support/topic/waf-rules-in-a-stateless-environment/#post-11549432
if [[ -f "${PUBLIC_PATH}/wp-content/plugins/wordfence/wordfence.php" ]]; then
  _good "Running wp eval for wordfence.php"
  wp eval "define('WFWAF_ALWAYS_ALLOW_FILE_WRITING',true); \
    wfConfig::save(array('wafStatus'=>'enabled'));"
fi
