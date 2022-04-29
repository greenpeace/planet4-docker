#!/usr/bin/env bash
set -e

[[ "${INSTALL_WORDPRESS}" = "true" ]] || exit 0

install_lock="${SOURCE_PATH}/.install"

_good "Setting permissions of composer to ${APP_USER}..."
chown -f "${APP_USER}" /app/bin/composer
chown -fR "${APP_USER}" /app/.composer
mkdir -p "${SOURCE_PATH}/artifacts" && chown -fR "${APP_USER}" "${SOURCE_PATH}/artifacts"

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

  if [[ ! -d "$dir" ]]; then
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
  rm -fr "${PUBLIC_PATH}:?}/*" "${PUBLIC_PATH}/.*" >/dev/null 2>&1 || true
}
# ==============================================================================
# create_source_path()
#
function create_source_path() {
  [[ ! -e "${SOURCE_PATH}" ]] && _good "Creating ${SOURCE_PATH} ..." && mkdir -p "${SOURCE_PATH}"
  return 0
}
# ==============================================================================
# touch_install_lock()
#
function touch_install_lock() {
  _good "Creating install lock file: ${install_lock}"
  true >"${install_lock}"
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
milliseconds=$((RANDOM % 1000))
_good "Sleeping ${milliseconds}ms ..."
sleep ".${milliseconds}"

num_files="$(get_num_files_exist)"

# Install-lock system resolution
sync
if [[ -f "${install_lock}" ]]; then
  _good "Installation already underway, ${install_lock} exists. Sleeping..."
  until [[ ! -f "${install_lock}" ]]; do
    sleep .1
  done
  _good "Install finished, resuming startup ..."
  create_source_directories
  exit 0
fi

# Create install lock in potential concurrent install environments only
create_source_path
if [[ "${APP_ENV}" != "local" ]]; then
  touch_install_lock
fi

_good "Number of files in source folder: ${num_files}"

# Check for test data files
if [[ "${num_files}" -eq 1 ]]; then
  if [[ -f "${PUBLIC_PATH}/index.php" ]] && [[ "$(grep TEST-DATA-ONLY "${PUBLIC_PATH}/index.php")" ]]; then
    _good "Test data detected, deleting source directories..."
    delete_source_directories
  elif [[ -f "${PUBLIC_PATH}/index.html" ]] && [[ "$(grep TEST-DATA-ONLY "${PUBLIC_PATH}/index.html")" ]]; then
    _good "Test data detected, deleting source directories..."
    delete_source_directories
  fi
elif [[ "${num_files}" -eq 2 ]]; then
  if [[ -f "${PUBLIC_PATH}/index.php" ]] &&
    [[ -f "${PUBLIC_PATH}/health_php.php" ]] &&
    grep -q TEST-DATA-ONLY "${PUBLIC_PATH}/index.php"; then
    _good "Test data detected, deleting source directories..."
    delete_source_directories
  else
    _warning "Unknown file detected"
    cat "${PUBLIC_PATH}/index.php" || true
    _warning "Attempting to continue ..."
  fi
elif [[ "${num_files}" -gt 0 ]]; then
  _good "${num_files} files found in ${PUBLIC_PATH} folder"

  if [[ "${OVERWRITE_EXISTING_FILES,,}" = "true" ]] || [[ "${DELETE_EXISTING_FILES,,}" = "true" ]]; then
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
if [[ "${DELETE_EXISTING_FILES,,}" = "true" ]]; then
  _good "Deleting source directories..."
  delete_source_directories
fi

create_source_directories

_good "Setting permissions of /app to ${APP_USER}..."
find /app ! -user "${APP_USER}" -exec chown -f "${APP_USER}" {} \;

# ==============================================================================
# ENVIRONMENT VARIABLE CHECKS
# ==============================================================================

if [[ -z "${WP_DB_HOST}" ]]; then
  _error "WP_DB_HOST cannot be blank"
else
  _good "WP_DB_HOST         ${WP_DB_HOST}"
fi

if [[ -z "${WP_DB_NAME}" ]]; then
  _error "WP_DB_NAME cannot be blank"
else
  _good "WP_DB_NAME         ${WP_DB_NAME}"
fi

if [[ -z "${WP_DB_USER}" ]]; then
  _error "WP_DB_USER cannot be blank"
else
  _good "WP_DB_USER         ${WP_DB_USER}"
fi

if [[ -z "${WP_DB_PASS}" ]]; then
  _error "WP_DB_PASS cannot be blank"
fi
_good "WP_DB_PREFIX           ${WP_DB_PREFIX}"

# ==============================================================================
# WORDPRESS INSTALLATION
# ==============================================================================

_good "Installing Wordpress for site ${WP_HOSTNAME:-$APP_HOSTNAME} ..."

function checkout() {
  set -x
  git config --system --add safe.directory /app/source
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
if [[ ! -f "${SOURCE_PATH}/composer.json" ]]; then
  _good "Checkout: ${GIT_SOURCE}:${GIT_REF}"
  mkdir -p "${SOURCE_PATH}"
  cd "${SOURCE_PATH}"
  checkout "${GIT_SOURCE}" "${GIT_REF}"
fi

if [[ -n "${MERGE_SOURCE}" ]]; then
  _good "Merge:   ${MERGE_SOURCE}:${MERGE_REF}"
  mkdir -p /app/merge
  cd /app/merge
  checkout "${MERGE_SOURCE}" "${MERGE_REF}"
  rsync -a --exclude=.* . "${SOURCE_PATH}"
fi

composer_exec="time setuser ${APP_USER} composer -vv --no-ansi"

# if [[ ! -d "${SOURCE_PATH}/composer.lock" ]]
# then
#   _good "Performing composer update..."
#   $composer_exec update
# fi

if [[ $APP_ENV =~ develop ]] || [[ "${APP_ENV}" = "local" ]]; then
  composer_install_flags=" --prefer-dist"
else
  composer_install_flags=" --prefer-dist --no-dev"
fi

_good "Setting permissions of /app to ${APP_USER}..."
find /app ! -user "${APP_USER}" -exec chown -f "${APP_USER}" {} \;

cd "${SOURCE_PATH}"

if [[ ! -d "vendor" ]]; then
  _good "Performing composer install..."
  $composer_exec install $composer_install_flags
fi

[[ -e "$PUBLIC_PATH/index.php" ]] && rm -f "$PUBLIC_PATH/index.php"

chown -R "${APP_USER}:${APP_USER}" "$PUBLIC_PATH"

# Get WP_VERSION from NRO. If it's empty fallback to base.
WP_VERSION=$(jq -r '.extra["wp-version"] // empty' <"${SOURCE_PATH}"/composer-local.json)
if [ -z "$WP_VERSION" ]; then
  WP_VERSION=$(jq -r '.extra["wp-version"] // empty' <"${SOURCE_PATH}"/composer.json)
fi
if [ -z "$WP_VERSION" ]; then
  echo "WP_VERSION not set"
  exit 1
fi
export WP_VERSION
echo "Using WP_VERSION: ${WP_VERSION}"

wp --root core download --version="${WP_VERSION}" --force "${WP_DOWNLOAD_FLAGS}"

$composer_exec copy:themes
$composer_exec copy:plugins

# Generate wp config file
chown -f "${APP_USER}" /app/bin/generate_wp*
setuser "${APP_USER}" /app/bin/generate_wp_keys.sh
setuser "${APP_USER}" /app/bin/generate_wp_config.sh

# Wait up to two minutes for the database to become ready
timeout=2
i=0
until dockerize -wait "tcp://${WP_DB_HOST}:${WP_DB_PORT}" -timeout 60s mysql -h "${WP_DB_HOST}" -u "${WP_DB_USER}" --password="${WP_DB_PASS}" -e "use ${WP_DB_NAME}"; do
  i=$((i + 1))
  [[ $i -gt $timeout ]] && _error "Timeout waiting for database to become ready" && exit 1
done

_good "Database ready: ${WP_DB_HOST}:${WP_DB_PORT}"

# FIXME Run another check to test if wp is installed yet
# FIXME If installed, perform site-update?

wp core install --url="${WP_HOSTNAME}" --title="$WP_TITLE" --admin_user="${WP_ADMIN_USER:-admin}" --admin_email="${WP_ADMIN_EMAIL:-$MAINTAINER_EMAIL}"
wp plugin activate --all --skip-plugins=wordfence

# FIXME Determine which theme to activate
# FIXME Why does the composer theme install script fail?
wp theme activate "${WP_THEME}"

$composer_exec core:add-author-capabilities

$composer_exec core:add-contributor-capabilities

$composer_exec site:global

clear_install_lock

date >"${PUBLIC_PATH}/.installed"
