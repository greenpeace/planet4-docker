#!/usr/bin/env bash
set -ea
set +u

# ----------------------------------------------------------------------------

# LOAD DEFAULT CONFIGURATION

# Read parameters from key=value configuration file
# Note this will override environment variables at this stage
# @todo prioritise ENV over config file ?

default_config="${GIT_ROOT_DIR}/config.default"
if [[ -f "${default_config}" ]]
then
  # shellcheck source=/dev/null
  . "${default_config}"
fi

# ----------------------------------------------------------------------------

# LOAD CUSTOM CONFIGURATION
if [[ ! -z "${CONFIG_FILE}" ]]
then
  echo "Reading custom configuration from ${CONFIG_FILE}"

  if [[ ! -f "${CONFIG_FILE}" ]]
  then
    _fatal "File not found: ${CONFIG_FILE}"
  fi
  # https://github.com/koalaman/shellcheck/wiki/SC1090
  # shellcheck source=/dev/null
  . "${CONFIG_FILE}"
fi

# ----------------------------------------------------------------------------
# Configure build variables based on CircleCI environment vars

if [[ "${CIRCLECI}" ]]
then
  if [[ -z "${BUILD_TAG}" ]]
  then
    if [[ "${CIRCLE_TAG}" ]]
    then
      BUILD_TAG="${CIRCLE_TAG}"
    elif [[ "${CIRCLE_BRANCH}" ]]
    then
      BUILD_TAG="${CIRCLE_BRANCH}"
    fi
  fi
  BUILD_NUM="build-${CIRCLE_BUILD_NUM}"
fi


APPLICATION_NAME=${APPLICATION_NAME:-${DEFAULT_APPLICATION_NAME}}
BASEIMAGE_VERSION=${BASEIMAGE_VERSION:-${DEFAULT_BASEIMAGE_VERSION}}
BRANCH_NAME=${BRANCH_NAME//[^a-zA-Z0-9\._-]/-}
BRANCH_NAME=${CIRCLE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}
BUILD_LOCALLY=${BUILD_LOCALLY:-${DEFAULT_BUILD_LOCALLY}}
BUILD_NAMESPACE=${BUILD_NAMESPACE:-${DEFAULT_BUILD_NAMESPACE}}
BUILD_NUM=${BUILD_NUM:-"test-${USER}-$(hostname -s)"}
BUILD_NUM=${BUILD_NUM//[^a-zA-Z0-9\._-]/-}
BUILD_REMOTELY=${BUILD_REMOTELY:-${DEFAULT_BUILD_REMOTELY}}
BUILD_TAG=${BUILD_TAG:-${BRANCH_NAME}}
BUILD_TAG=${BUILD_TAG//[^a-zA-Z0-9\._-]/-}
BUILD_TIMEOUT=${BUILD_TIMEOUT:-${DEFAULT_BUILD_TIMEOUT}}
COMPOSER=${COMPOSER:-${DEFAULT_COMPOSER}}
CONTAINER_TIMEZONE=${CONTAINER_TIMEZONE:-$DEFAULT_CONTAINER_TIMEZONE}
DOCKERIZE_VERSION=${DOCKERIZE_VERSION:-$DEFAULT_DOCKERIZE_VERSION}
GIT_REF=${GIT_REF:-${DEFAULT_GIT_REF}}
GIT_SOURCE=${GIT_SOURCE:-${DEFAULT_GIT_SOURCE}}
GOOGLE_PROJECT_ID=${GOOGLE_PROJECT_ID:-${DEFAULT_GOOGLE_PROJECT_ID}}
NGX_PAGESPEED_RELEASE=${NGX_PAGESPEED_RELEASE:-${DEFAULT_NGX_PAGESPEED_RELEASE}}
NGX_PAGESPEED_VERSION=${NGX_PAGESPEED_VERSION:-${DEFAULT_NGX_PAGESPEED_VERSION}}
OPENRESTY_VERSION=${OPENRESTY_VERSION:-${DEFAULT_OPENRESTY_VERSION}}
OPENSSL_VERSION=${OPENSSL_VERSION:-${DEFAULT_OPENSSL_VERSION}}
PHP_MAJOR_VERSION=${PHP_MAJOR_VERSION:-${DEFAULT_PHP_MAJOR_VERSION}}
PULL_IMAGES=${PULL_IMAGES:-${DEFAULT_PULL_IMAGES}}
REVISION_TAG=${REVISION_TAG:-$(git rev-parse --short HEAD)}
REWRITE_LOCAL_DOCKERFILES=${REWRITE_LOCAL_DOCKERFILES:-${DEFAULT_REWRITE_LOCAL_DOCKERFILES}}
SOURCE_VERSION=${SOURCE_VERSION:-${BRANCH_NAME}}
SOURCE_VERSION=${SOURCE_VERSION//[^a-zA-Z0-9\._-]/-}
