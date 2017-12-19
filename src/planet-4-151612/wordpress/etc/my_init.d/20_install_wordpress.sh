#!/usr/bin/env bash
set -e

install_lock="/app/source/public/.install"

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

# ==============================================================================
# get_num_files_exist()
#
# Displays the number of files in a directory.
#
# shellcheck disable=SC2120
function get_num_files_exist() {
  local -a files
  local dir
  dir="${1:-/app/source/public}"

  if [[ ! -d "$dir" ]]
  then
    echo 0
    exit 0
  fi
  shopt -s nullglob dotglob
  files=(/app/source/public/*)
  shopt -u nullglob dotglob
  echo "${#files[@]}"
}
# ==============================================================================
# create_source_directories()
#
function create_source_directories() {
  [[ ! -e /app/source/public ]] && mkdir -p /app/source/public
  [[ ! -e /app/www ]] && ln -s /app/source/public /app/www
}
# ==============================================================================
# delete_source_directories()
#
function delete_source_directories() {
  # Force clean exit code in the event that these are bind-mounted
  rm -fr /app/www || true
  rm -fr /app/source/public /app/source/public/* /app/source/public/.*  || true
}
# ==============================================================================
# touch_install_lock()
#
function touch_install_lock() {
  mkdir -p /app/source/public
  true > "${install_lock}"
}
# ==============================================================================
# clear_install_lock()
#
function clear_install_lock() {
  rm -fr "${install_lock}"
}

# ==============================================================================
# FILE SYSTEM CHECKS
# ==============================================================================

# Random sleep from 0ms to 1000ms to avoid race conditions with multiple containers
milliseconds="$[ ( $RANDOM % 1000 ) ]"
_good "Sleeping ${milliseconds}ms ..."
sleep ".${milliseconds}"

num_files="$(get_num_files_exist)"

if [[ -f "${install_lock}" ]]
then
  _good "Installation already underway, ${install_lock} exists. Sleeping..."
  until [[ ! -f "${install_lock}" ]]
  do
    sleep .1
  done
  _good "Install finished, resuming startup ..."
  create_source_directories
  exit 0
fi

touch_install_lock

_good "Number of files in source folder: ${num_files}"

# Check for test data files
if [[ "${num_files}" -eq 1 ]]
then
  if [[ -f "/app/source/public/index.php" ]] && [[ "$(grep TEST-DATA-ONLY /app/source/public/index.php)" ]]
  then
    _good "Test data detected, deleting source directories..."
    delete_source_directories
  elif [[ -f "/app/source/public/index.html" ]] && [[ "$(grep TEST-DATA-ONLY /app/source/public/index.html)" ]]
  then
    _good "Test data detected, deleting source directories..."
    delete_source_directories
  fi
elif [[ "${num_files}" -eq 2 ]] && \
  [[ -f "/app/source/public/index.php" ]] && [[ "$(grep TEST-DATA-ONLY /app/source/public/index.php)" ]] && \
  [[ -f "/app/source/public/index.html" ]] && [[ "$(grep TEST-DATA-ONLY /app/source/public/index.html)" ]]
then
  _good "Test data detected, deleting source directories..."
  delete_source_directories
elif [[ "${num_files}" -gt 0 ]] && [[ "${OVERWRITE_FILES,,}" != "true" ]]
then
  _good "OVERWRITE_FILES is not 'true', cowardly refusing to reinstall Wordpress"
  create_source_directories
  rm -f "${install_lock}"
  # Exit this script and continue container boot
  exit 0
fi

# Clean up if we're starting fresh
if [[ "${OVERWRITE_FILES,,}" = "true" ]]
then
    _good "Deleting source directories..."
    delete_source_directories
    touch_install_lock
fi

create_source_directories

_good "Setting permissions of /app to ${APP_USER}..."
chown -R ${APP_USER} /app || true

# ==============================================================================
# ENVIRONMENT VARIABLE CHECKS
# ==============================================================================

if [[ -z "${WP_DB_HOST}" ]]
then
    _error "WP_DB_HOST cannot be blank"
else
    _good "WP_DB_HOST         ${WP_DB_HOST}"
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
_good "WP_DB_PREFIX           ${WP_DB_PREFIX}"

# FIXME this is a terribly hacky way of checking upstream
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
else
  _good "COMPOSER           ${COMPOSER}"
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

_good "Installing Wordpress for site ${WP_HOSTNAME:-$APP_HOSTNAME} ..."
_good "From: ${GIT_SOURCE}:${GIT_REF}"

composer --profile -vv copy:wordpress

composer --profile -vv reset:themes
composer --profile -vv reset:plugins

composer --profile -vv copy:themes
composer --profile -vv copy:assets
composer --profile -vv copy:plugins

setuser ${APP_USER} dockerize -template /app/wp-config.php.tmpl:/app/source/public/wp-config.php

# Wait up to two minutes for the database to become ready
timeout=2
i=0
until dockerize -wait tcp://${WP_DB_HOST}:${WP_DB_PORT} -timeout 60s mysql -h "${WP_DB_HOST}" -u "${WP_DB_USER}" --password="${WP_DB_PASS}" -e "use ${WP_DB_NAME}"
do
  let i=i+1
  if [[ $i -gt $timeout ]]
  then
    _error "Timeout waiting for database to become ready"
    exit 1
  fi
done

_good "Database ready: ${WP_DB_HOST}:${WP_DB_PORT}"

# FIXME Run another check to test if wp is installed yet
# FIXME If installed, perform site-update?

composer --profile -vv core:install

composer --profile -vv plugin:activate

composer --profile -vv theme:activate

composer --profile -vv core:initial-content

# Links the source directory to expected path
# FIXME create APP_SOURCE_DIRECTORY var for '/app/www' '/app/source'
[[ ! -e /app/www ]] && ln -s /app/source/public /app/www || true

clear_install_lock
