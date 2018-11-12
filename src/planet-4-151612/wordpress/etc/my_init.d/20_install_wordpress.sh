#!/usr/bin/env bash
set -e

[[ "${INSTALL_WORDPRESS}" = "true" ]] || exit 0

install_lock="${SOURCE_PATH}/.install"

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
  dir="${1:-${PUBLIC_PATH}}"

  if [[ ! -d "$dir" ]]
  then
    echo 0
    return 0
  fi
  shopt -s nullglob dotglob
  files=(${PUBLIC_PATH}/*)
  shopt -u nullglob dotglob
  echo "${#files[@]}"
}
# ==============================================================================
# create_source_directories()
#
function create_source_directories() {
  [[ -e "${PUBLIC_PATH}" ]] && return 0
  _good "Creating source directory: ${PUBLIC_PATH}"
  mkdir -p "${PUBLIC_PATH}"
}
# ==============================================================================
# delete_source_directories()
#
function delete_source_directories() {
  # Force clean exit code in the event that these are bind-mounted
  _good "Deleting source directory: ${PUBLIC_PATH}"
  rm -fr "${PUBLIC_PATH}:?}/*" "${PUBLIC_PATH}/.*" >/dev/null 2>&1  || true
}
# ==============================================================================
# touch_install_lock()
#
function touch_install_lock() {
  [[ ! -e "${SOURCE_PATH}" ]] && _good "Creating ${SOURCE_PATH} ..." && mkdir -p "${SOURCE_PATH}"
  _good "Creating install lock file: ${install_lock}"
  true > "${install_lock}"
}
# ==============================================================================
# clear_install_lock()
#
function clear_install_lock() {
  _good "Removing install lock file: ${install_lock}"
  rm -fr "${install_lock}"
}

# ==============================================================================
# FILE SYSTEM CHECKS
# ==============================================================================

# FIXME Race conditions still exist! Best to init shared file systems once with
# a single container before scaling.
# Random sleep from 0ms to 1000ms to avoid race conditions with multiple containers
milliseconds=$(( RANDOM % 1000 ))
_good "Sleeping ${milliseconds}ms ..."
sleep ".${milliseconds}"

num_files="$(get_num_files_exist)"

sync
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
  if [[ -f "${PUBLIC_PATH}/index.php" ]] && [[ "$(grep TEST-DATA-ONLY "${PUBLIC_PATH}/index.php")" ]]
  then
    _good "Test data detected, deleting source directories..."
    delete_source_directories
  elif [[ -f "${PUBLIC_PATH}/index.html" ]] && [[ "$(grep TEST-DATA-ONLY "${PUBLIC_PATH}/index.html")" ]]
  then
    _good "Test data detected, deleting source directories..."
    delete_source_directories
  fi
elif [[ "${num_files}" -eq 2 ]] && \
  [[ -f "${PUBLIC_PATH}/index.php" ]] && [[ "$(grep TEST-DATA-ONLY "${PUBLIC_PATH}/index.php")" ]] && \
  [[ -f "${PUBLIC_PATH}/index.html" ]] && [[ "$(grep TEST-DATA-ONLY "${PUBLIC_PATH}/index.html")" ]]
then
  _good "Test data detected, deleting source directories..."
  delete_source_directories
elif [[ "${num_files}" -gt 0 ]]
then
  _good "${num_files} files found in ${PUBLIC_PATH} folder"

  if [[ "${OVERWRITE_EXISTING_FILES,,}" = "true" ]] || [[ "${DELETE_EXISTING_FILES,,}" = "true" ]]
  then
    _good "Continuing with installation ..."
  else
    _good "Non-default files found in directory, and OVERWRITE_EXISTING_FILES != true"
    _good "Exiting installation script ..."
    # FIXME this is a hack!
    # But not worth exploring the fix at this point.
    clear_install_lock
    exit 0
  fi
fi

# Clean up if we're starting fresh
if [[ "${DELETE_EXISTING_FILES,,}" = "true" ]]
then
    _good "Deleting source directories..."
    delete_source_directories
fi

create_source_directories

_good "Setting permissions of /app to ${APP_USER}..."
chown -R "${APP_USER}" /app || true

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

# ==============================================================================
# WORDPRESS INSTALLATION
# ==============================================================================

_good "Installing Wordpress for site ${WP_HOSTNAME:-$APP_HOSTNAME} ..."

function checkout() {
  set -x
  git init
  git remote add origin $1
  git fetch --tags
  # git reset $2
  git checkout $2 -f
  { set +x; } 2>/dev/null
  _good "git log -1"
  git log -1
  echo
  ls -al .
}

# Ensure the expected composer.json file is found
if [[ ! -f "${SOURCE_PATH}/composer.json" ]]
then
  _good "Checkout: ${GIT_SOURCE}:${GIT_REF}"
  mkdir -p "${SOURCE_PATH}"
  cd "${SOURCE_PATH}"
  checkout ${GIT_SOURCE} ${GIT_REF}
fi

if [[ ! -z "${MERGE_SOURCE}" ]]
then
  _good "Merge:   ${MERGE_SOURCE}:${MERGE_REF}"
  mkdir -p /app/merge
  cd /app/merge
  checkout ${MERGE_SOURCE} ${MERGE_REF}
  rsync -av --exclude=.* . "${SOURCE_PATH}"
fi

composer_exec="composer --profile -vv --no-ansi"

# if [[ ! -d "${SOURCE_PATH}/composer.lock" ]]
# then
#   _good "Performing composer update..."
#   $composer_exec update
# fi

if [[ $APP_ENV =~ develop ]]
then
  composer_install_flags=" --prefer-dist"
else
  composer_install_flags=" --prefer-dist --no-dev"
fi

cd "${SOURCE_PATH}"

if [[ ! -d "vendor" ]]
then
  _good "Performing composer install..."
  $composer_exec install $composer_install_flags
fi

$composer_exec download:wordpress

$composer_exec reset:themes
$composer_exec reset:plugins

$composer_exec copy:themes
$composer_exec copy:assets
$composer_exec copy:plugins

setuser "${APP_USER}" dockerize -template "/app/wp-config.php.tmpl:${PUBLIC_PATH}/wp-config.php"

# Wait up to two minutes for the database to become ready
timeout=2
i=0
until dockerize -wait "tcp://${WP_DB_HOST}:${WP_DB_PORT}" -timeout 60s mysql -h "${WP_DB_HOST}" -u "${WP_DB_USER}" --password="${WP_DB_PASS}" -e "use ${WP_DB_NAME}"
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

wp core install --url="${WP_HOSTNAME}" --title="$WP_TITLE" --admin_user="${WP_ADMIN_USER:-admin}" --admin_email="${WP_ADMIN_EMAIL:-$MAINTAINER_EMAIL}"

wp plugin activate --all

# FIXME Determine which theme to activate
# FIXME Why does the composer theme install script fail?
wp theme activate "${WP_THEME}"

[[ "${WP_DEFAULT_CONTENT}" = "true" ]] && $composer_exec core:initial-content

$composer_exec core:add-author-capabilities

$composer_exec core:add-contributor-capabilities

$composer_exec site:global

clear_install_lock

date > "${PUBLIC_PATH}/.installed"
