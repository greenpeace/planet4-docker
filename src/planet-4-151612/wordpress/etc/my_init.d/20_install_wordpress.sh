#!/usr/bin/env bash
set -e

# shellcheck disable=SC2120
function files_exist() {
  local files
  # Check if files exist
  # This indicates whether the container is mounting files from an external source
  # If files exist we may not want to overwrite
  if [[ -d "${1:-/app/source/public}" ]]
  then
    # Directory already exists
    shopt -s nullglob dotglob
    files=(/app/source/public/*)
    shopt -u nullglob dotglob
    echo "${#files[@]}"
    exit 0
  else
    echo 0
  fi
}

function delete_source_directories() {
  # Force clean exit code in the event that these are bind-mounted
  rm -fr /app/www || true
  rm -fr /app/source/public/* /app/source/public/.* /app/source/public || true
  mkdir -p /app/source/public
  true > "/app/source/public/.installing"
}

# ==============================================================================
# ENVIRONMENT VARIABLE CHECKS
# ==============================================================================

if [[ -z "${WP_DB_HOST}" ]]
then
    _error "WP_DB_HOST cannot be blank"
elif [[ "$WP_DB_HOST" = "db" ]]
then
    _warning "Using default WP_DB_HOST: db"
else
    _good "WP_DB_HOST         $WP_DB_HOST"
fi

if [[ -z "${WP_DB_NAME}" ]]
then
    _error "WP_DB_NAME cannot be blank"
else
    _good "WP_DB_NAME         ${WP_DB_NAME}"
fi

if [[ -z "${WP_DB_USER}" ]]
then
    _error "WP_DB_USER cannot be blank"
else
    _good "WP_DB_USER         ${WP_DB_USER}"
fi

if [[ -z "${WP_DB_PASS}" ]]
then
    _error "WP_DB_PASS cannot be blank"
fi
_good "WP_DB_PREFIX       ${WP_DB_PREFIX}"

# ==============================================================================
# FILE SYSTEM CHECKS
# ==============================================================================

if [[ -f "/app/source/public/.installing" ]]
then
  _good "Installation already underway, skipping..."
  # Ensure the symlink exists
  [[ ! -e /app/www ]] && ln -s /app/source/public /app/www
  exit 0
fi

files="$(files_exist)"

true > "/app/source/public/.installing"

if [[ "${files}" -eq 1 ]] && [[ $(grep -q TEST-DATA-ONLY /app/source/public/index.php) ]]
then
  _good "Test data detected, deleting /app/source/public /app/www"
  delete_source_directories
elif [[ "${files}" -ne 0 ]] && [[ "${OVERWRITE_FILES,,}" != "true" ]]
then
  _good "OVERWRITE_FILES is not 'true', cowardly refusing to reinstall Wordpress"

  # Ensure the symlink exists
  [[ ! -e /app/www ]] && ln -s /app/source/public /app/www

  # Exit this script and continue container boot
  exit 0
fi

# Clean up if we're starting fresh
if [[ "${OVERWRITE_FILES,,}" = "true" ]]
then
    _good "Deleting source directories..."
    delete_source_directories
fi

# Ensure the expected composer.json file is found
if [[ ! -f "/app/source/${COMPOSER}" ]]
then
  ls -al /app/source/
  _error "File not found: $PWD/$COMPOSER"
fi

# ==============================================================================
# WORDPRESS INSTALLATION
# ==============================================================================

_good "Installing Wordpress for site ${WP_HOSTNAME}..."

mkdir -p /app/source/public

chown -R ${APP_USER:-$DEFAULT_APP_USER}:${APP_GROUP:-$DEFAULT_APP_GROUP} /app

# Overwrite the stock wp-config to use environment variables (again?)
dockerize -template /app/wp-config.php.tmpl:/app/source/public/wp-config.php

# Wait for SQL server then run composer site-install
until dockerize -wait tcp://${WP_DB_HOST}:3306 -timeout 60s mysql -h ${WP_DB_HOST} -u ${WP_DB_USER} --password="${WP_DB_PASS}" -e "use ${WP_DB_NAME}"; do
  sleep 1;
done

# @todo this is a terribly hacky way of checking upstream, fixme please
actual_source="https://github.com/$(git remote -v | grep fetch | cut -d':' -f2 | cut -d'/' -f4)/$(git remote -v | grep fetch | cut -d':' -f2 | cut -d'/' -f5 | cut -d' ' -f1)"
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

cd /app/source

/app/bin/composer --profile -vv site-install
/app/bin/composer --profile -vv core:add-super-admin-user

# Links the source directory to expected path
# FIXME create APP_SOURCE_DIRECTORY var for '/app/www' '/app/source'
[[ ! -e /app/www ]] && ln -s /app/source/public /app/www || true

# Wordpress configuration startup
# /app/bin/wp.sh option set siteurl "${WP_SITE_PROTOCOL}://${WP_SITE_URL}/"
# /app/bin/wp.sh option set home "${WP_SITE_PROTOCOL}://${WP_SITE_HOME}"

exit 0
