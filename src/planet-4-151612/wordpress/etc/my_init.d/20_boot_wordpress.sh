#!/usr/bin/env bash

source /app/bin/env.sh

# Check if files exist
# This indicates whether the container is mounting files from an external source
# If files exist we may not want to overwrite
if [ -d "/app/source/public" ]; then
  # Directory already exists
files=$(shopt -s nullglob dotglob; echo /app/source/public/*)
  # Check if files exist
  if [ "${#files}" != "0" ]; then
    echo "Files exist in /app/source/public"

    if [ "${OVERWRITE_FILES,,}" != "true" ]; then
      _good "OVERWRITE_FILES is not 'true', cowardly refusing to reinstall Wordpress"

      # Ensure the symlink exists
      [ ! -e /app/www ] && ln -s /app/source/public /app/www

      # Exit this script
      exit 0
    fi
  fi
fi

# ==============================================================================
# PRE-INSTALLATION CHECKS
#

# Check if all required environment variables are set

if [ "${OVERWRITE_FILES,,}" == "true" ]; then
    _good "Deleting /app/source/public..."
    # Force clean exit code in the event that public is bind-mounted
    rm -fr /app/source/public/* /app/source/public/.* /app/source/public || true
    mkdir -p /app/source/public
fi

if [ "$WP_DB_HOST" == "db" ]; then
    _warning "Using default WP_DB_HOST: db"
else
    _good "WP_DB_HOST         $WP_DB_HOST"
fi

if [ "${WP_DB_NAME}" == "" ]; then
    _error "WP_DB_NAME cannot be blank"
else
    _good "WP_DB_NAME         ${WP_DB_NAME}"
fi

if [ "${WP_DB_USER}" == "" ]; then
    _error "WP_DB_USER cannot be blank"
else
    _good "WP_DB_USER         ${WP_DB_USER}"
fi

if [ "${WP_DB_PASS}" == "" ]; then
    _error "WP_DB_PASS cannot be blank"
fi
_good "WP_DB_PREFIX       ${WP_DB_PREFIX}"

cd /app/source || exit 1

if [[ ! -f "${PWD}/${COMPOSER}" ]]
then
  ls -al
  _error "File not found: $PWD/$COMPOSER"
else
  cat "$COMPOSER"
fi

# WORDPRESS INSTALLATION

_good "Installing Wordpress for site ${WP_HOSTNAME}..."

mkdir -p /app/source/public
chown ${APP_USER:-${DEFAULT_APP_USER}} /app/source/public

# Overwrite the stock wp-config to use environment variables (again?)
cp /app/wp-config.php.default /app/source/public/wp-config.php

# Wait for SQL server then run composer site-install
until /usr/local/bin/dockerize -wait tcp://${WP_DB_HOST}:3306 -timeout 5s mysql -h ${WP_DB_HOST} -u ${WP_DB_USER} --password="${WP_DB_PASS}" -e "use ${WP_DB_NAME}"; do
  sleep 1;
done

# @todo this is a terribly hacky way of checking upstream, fixme please
actual_source="https://github.com/$(git remote -v | grep fetch | cut -d':' -f2 | cut -d' ' -f1 | cut -d'.' -f1)"
if [[ ${GIT_SOURCE} != "${actual_source}" ]]
then
  _warning "Expected source:     ${GIT_SOURCE}"
  _warning "Found source:        ${actual_source}"
fi

actual_git_ref=$(git rev-parse --abbrev-ref HEAD)
if [[ ${GIT_REF} != "${actual_git_ref}" ]]
then
  _warning "Expected branch/tag: ${GIT_REF}"
  _warning "Found branch/tag:    ${actual_git_ref}"
fi

_good "Running 'composer site-install' with COMPOSER=${COMPOSER}"

/usr/local/bin/composer --profile -vvv site-install

# Links the source directory to expected path
# @todo remap all references to '/app/www' in docker parents to an ENV var
[[ ! -e /app/www ]] && ln -s /app/source/public /app/www || true

# Wordpress configuration startup
# /app/bin/wp.sh option set siteurl "${WP_SITE_PROTOCOL}://${WP_SITE_URL}/"
# /app/bin/wp.sh option set home "${WP_SITE_PROTOCOL}://${WP_SITE_HOME}"

exit 0
