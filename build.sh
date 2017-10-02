#!/usr/bin/env bash
set -xe

# Read configuration from config file

# Helper functions
function fatal() {
  echo -e "ERROR: $1" >&2
  exit 1
}

function usage {
  fatal "Usage: $0 [OPTION] [BUILD_TYPE]...
Build and test artifacts in this repository

Example:
  \$1 platform
        Uses cloudbuild-platform.yaml

  \$1 site
        Uses cloudbuild-site.yaml

Options:
  -c    Configuration file for build variables, eg:
        $0 -c config
  -l    Perform the docker build locally (default: false)
  -r    Perform the docker build remotely (default: true)
"
}

OPTIONS=':c:lr'
while getopts $OPTIONS option
do
    case $option in
        c  )    CONFIG_FILE=$OPTARG;;
        l  )    BUILD_LOCALLY='true';;
        r  )    BUILD_REMOTELY='true';;
        *  )    usage;;
    esac
done
shift $(($OPTIND - 1))

# Read parameters from key->value configuration files
# Note this will override environment variables at this stage
# @todo prioritise ENV over config file ?

DEFAULT_CONFIG_FILE="./config.default"
if [ -f "${DEFAULT_CONFIG_FILE}" ]; then
  # shellcheck source=/dev/null
  source ${DEFAULT_CONFIG_FILE}
fi

# Read from custom config file from command line parameter
if [ "${CONFIG_FILE}" != "" ]; then
  echo "Reading custom configuration from ${CONFIG_FILE}"

  if [ ! -f "${CONFIG_FILE}" ]; then
    fatal "File not found: ${CONFIG_FILE}"
  fi
  # https://github.com/koalaman/shellcheck/wiki/SC1090
  # shellcheck source=/dev/null
  source ${CONFIG_FILE}
fi

# which cloudbuild yaml file to submit
[ -z "$1" ] && BUILD_TYPE=${DEFAULT_BUILD_TYPE} || BUILD_TYPE="$1"

BUILD_NAMESPACE=${BUILD_NAMESPACE:-${DEFAULT_BUILD_NAMESPACE}}
# Perform the Docker build locally
BUILD_LOCALLY=${BUILD_LOCALLY:-${DEFAULT_BUILD_LOCALLY}}

# Perform the build on GCR
BUILD_REMOTELY=${BUILD_REMOTELY:-${DEFAULT_BUILD_REMOTELY}}

# Whether to update local Dockerfiles with new version numbers
REWRITE_LOCAL_DOCKERFILES=${REWRITE_LOCAL_DOCKERFILES:-${DEFAULT_REWRITE_LOCAL_DOCKERFILES}}

# gcr.io project in which to store the images
GOOGLE_PROJECT_ID=${GOOGLE_PROJECT_ID:-${DEFAULT_GOOGLE_PROJECT_ID}}

BASEIMAGE_VERSION=${BASEIMAGE_VERSION:-${DEFAULT_BASEIMAGE_VERSION}}

NGINX_VERSION=${NGINX_VERSION:-${DEFAULT_NGINX_VERSION}}

NGINX_PAGESPEED_VERSION=${NGINX_PAGESPEED_VERSION:-${DEFAULT_NGINX_PAGESPEED_VERSION}}
NGINX_PAGESPEED_RELEASE=${NGINX_PAGESPEED_RELEASE:-${DEFAULT_NGINX_PAGESPEED_RELEASE}}

OPENSSL_VERSION=${OPENSSL_VERSION:-${DEFAULT_OPENSSL_VERSION}}

HEADERS_MORE_VERSION=${HEADERS_MORE_VERSION:-${DEFAULT_HEADERS_MORE_VERSION}}

PHP_VERSION=${PHP_VERSION:-${DEFAULT_PHP_VERSION}}

# container builder will timeout and abort the build after:
BUILD_TIMEOUT=${BUILD_TIMEOUT:-${DEFAULT_BUILD_TIMEOUT}}

# application repository to build
GIT_SOURCE=${GIT_SOURCE:-${DEFAULT_GIT_SOURCE}}

# branch or tag of application repository to build
# see VCS repository composer documentation at:
# https://getcomposer.org/doc/05-repositories.md#vcs
# https://getcomposer.org/doc/02-libraries.md
GIT_REF=${GIT_REF:-${DEFAULT_GIT_REF}}

# set the composer and lock file to use in the repository
COMPOSER=${COMPOSER:-${DEFAULT_COMPOSER}}

# set source and destination tags
SOURCE_TAG=${SOURCE_TAG:-${DEFAULT_SOURCE_TAG}}
BUILD_TAG=${BUILD_TAG:-${DEFAULT_BUILD_TAG}}

# commit tag, defaults to short commit hash
REVISION_TAG=${REVISION_TAG:-$(git rev-parse --short HEAD)}

# container timezone
CONTAINER_TIMEZONE=${CONTAINER_TIMEZONE:-$DEFAULT_CONTAINER_TIMEZONE}

ROOT_DIR=$(pwd)
# Get all the project subdirectories
shopt -s nullglob
cd "${ROOT_DIR}/source/${GOOGLE_PROJECT_ID}"
SOURCE_DIRECTORY=(*/)
cd "${ROOT_DIR}"
shopt -u nullglob

for IMAGE in "${SOURCE_DIRECTORY[@]}"
do
  echo -e "->> ${GOOGLE_PROJECT_ID}/${IMAGE}"

  IMAGE=${IMAGE%/}

  # Check the source directory exists and contains a Dockerfile
  if [ -d "${ROOT_DIR}/source/${GOOGLE_PROJECT_ID}/${IMAGE}" ] && [ -f "${ROOT_DIR}/source/${GOOGLE_PROJECT_ID}/${IMAGE}/Dockerfile" ]; then
    BUILD_DIR="${ROOT_DIR}/source/${GOOGLE_PROJECT_ID}/${IMAGE}"
  else
    fatal "ERROR :: Dockerfile not found: source/${GOOGLE_PROJECT_ID}/Dockerfile"
  fi

  if [ "${REWRITE_LOCAL_DOCKERFILES}" = "true" ]; then

    # Select a sed tool for updating Dockfile build-time variables
    if type docker >/dev/null 2>&1; then
      # Prefer docker busybox for sed cross platform compatability
      SED_COMMAND="docker run --rm -v ${BUILD_DIR}:/app:cached busybox sed"
      SED_TARGET_LOCATION="/app"
    else
      # Hope local install is functional (not in OSX)
      echo "WARNING :: docker is not installed! Trying $(which sed)..."
      SED_COMMAND="sed"
      SED_TARGET_LOCATION="${BUILD_DIR}"
    fi

    if [ $IMAGE = 'ubuntu' ]; then
      # Update Dockerfile variables
      $SED_COMMAND -i -r \
        -e "s;FROM\s+.*/(.*);FROM phusion/baseimage:${BASEIMAGE_VERSION};g" \
        ${SED_TARGET_LOCATION}/Dockerfile
    else
      # Update Dockerfile variables
      $SED_COMMAND -i -r \
        -e "s;FROM\s+.*/(.*);FROM ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/\1;g" \
        -e "s;ENV NGINX_VERSION .*;ENV NGINX_VERSION ${NGINX_VERSION};g" \
        -e "s;ENV NGINX_PAGESPEED_VERSION .*;ENV NGINX_PAGESPEED_VERSION ${NGINX_PAGESPEED_VERSION};g" \
        -e "s;ENV NGINX_PAGESPEED_RELEASE .*;ENV NGINX_PAGESPEED_RELEASE ${NGINX_PAGESPEED_RELEASE};g" \
        -e "s;ENV OPENSSL_VERSION .*;ENV OPENSSL_VERSION ${OPENSSL_VERSION};g" \
        -e "s;ENV HEADERS_MORE_VERSION .*;ENV HEADERS_MORE_VERSION ${HEADERS_MORE_VERSION};g" \
        -e "s;ENV PHP_VERSION .*;ENV PHP_VERSION ${PHP_VERSION};g" \
        ${SED_TARGET_LOCATION}/Dockerfile
    fi

    # Update README variables
    $SED_COMMAND -i -r \
      -e "s;(nginx)([ -])[0-9\.]+;\1\2${NGINX_VERSION};ig" \
      -e "s;(ngx_pagespeed)([ -])[0-9\.]+;\1\2${NGINX_PAGESPEED_VERSION};ig" \
      -e "s;ngx_pagespeed-${NGINX_PAGESPEED_VERSION}-${NGINX_PAGESPEED_RELEASE};ngx_pagespeed-${NGINX_PAGESPEED_VERSION}--${NGINX_PAGESPEED_RELEASE}NGINX_PAGESPEED_RELEASE;ig" \
      -e "s;(openssl)([ -])[0-9a-z\.]+;\1\2${OPENSSL_VERSION};ig" \
      -e "s;(php)([ -])[0-9\.]+;\1\2${PHP_VERSION};ig" \
      ${SED_TARGET_LOCATION}/README.md
  fi

done

# Perform the build locally
if [ "${BUILD_LOCALLY}" = "true" ]; then


  # Need to explicitly define build order for local directory
  # cloudbuild.yaml defines a logical build structure but local is not alphanumeric
  LOCAL_BUILD_ORDER=(
    "ubuntu"
    "nginx-pagespeed"
    "nginx-php-exim"
    "wordpress"
    "p4-onbuild"
    "p4-gpi-app"
  )

  for IMAGE in "${LOCAL_BUILD_ORDER[@]}"; do

    # Check the source directory exists and contains a Dockerfile
    if [ -d "${ROOT_DIR}/source/${GOOGLE_PROJECT_ID}/${IMAGE}" ] && [ -f "${ROOT_DIR}/source/${GOOGLE_PROJECT_ID}/${IMAGE}/Dockerfile" ]; then
      BUILD_DIR="${ROOT_DIR}/source/${GOOGLE_PROJECT_ID}/${IMAGE}"
    elif [ -d "${ROOT_DIR}/sites/${GOOGLE_PROJECT_ID}/${IMAGE}" ] && [ -f "${ROOT_DIR}/source/${GOOGLE_PROJECT_ID}/${IMAGE}/Dockerfile" ]; then
      BUILD_DIR="${ROOT_DIR}/sites/${GOOGLE_PROJECT_ID}/${IMAGE}"
    else
      fatal "ERROR :: Dockerfile not found. Tried:\n - ./source/${GOOGLE_PROJECT_ID}/${IMAGE}/Dockerfile\n - ./sites/${GOOGLE_PROJECT_ID}/${IMAGE}/Dockerfile"
    fi

    echo -e "\nBuilding ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BUILD_TAG} ...\n"
    docker build \
      -t ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BUILD_TAG} \
      -t ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${REVISION_TAG}
      ${BUILD_DIR}
  done
fi

if [ "${BUILD_REMOTELY}" = "true" ]; then
  echo "Sending build context to Google Container Builder ..."

  case "${BUILD_TYPE}" in
    "site")
      # Rewrite cloudbuild variables
      SUBSTITUTIONS=(
        "_BUILD_NAMESPACE=${BUILD_NAMESPACE}" \
        "_BUILD_TAG=${BUILD_TAG}" \
        "_COMPOSER=${COMPOSER}" \
        "_GIT_REF=${GIT_REF}" \
        "_GOOGLE_PROJECT_ID=${GOOGLE_PROJECT_ID}" \
        "_REVISION_TAG=${REVISION_TAG}" \
        "_SOURCE_TAG=${SOURCE_TAG}"
      )
      ;;
    "platform")
      # Rewrite cloudbuild variables
      SUBSTITUTIONS=(
        "_BASEIMAGE_VERSION=${BASEIMAGE_VERSION}" \
        "_BUILD_NAMESPACE=${BUILD_NAMESPACE}" \
        "_BUILD_TAG=${BUILD_TAG}" \
        "_COMPOSER=${COMPOSER}" \
        "_CONTAINER_TIMEZONE=${CONTAINER_TIMEZONE}" \
        "_GIT_SOURCE=${GIT_SOURCE}" \
        "_GIT_REF=${GIT_REF}" \
        "_GOOGLE_PROJECT_ID=${GOOGLE_PROJECT_ID}" \
        "_HEADERS_MORE_VERSION=${HEADERS_MORE_VERSION}" \
        "_NGINX_VERSION=${NGINX_VERSION}" \
        "_NGINX_PAGESPEED_RELEASE=${NGINX_PAGESPEED_RELEASE}" \
        "_NGINX_PAGESPEED_VERSION=${NGINX_PAGESPEED_VERSION}" \
        "_OPENSSL_VERSION=${OPENSSL_VERSION}" \
        "_REVISION_TAG=${REVISION_TAG}" \
        "_SOURCE_TAG=${SOURCE_TAG}"
      )
      ;;
    *)
      fatal "Invalid build type ${BUILD_TYPE}"
      ;;
  esac

  SUBSTITUTIONS_PROCESSOR="$(printf "%s," "${SUBSTITUTIONS[@]}")"
  SUBSTITUTIONS_STRING="${SUBSTITUTIONS_PROCESSOR%,}"

  # Avoid sending entire .git history as build context to save some time and bandwidth
  TMPDIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")
  tar --exclude='.git/' -zcf $TMPDIR/docker-source.tar.gz .

  # Submit the build
  time gcloud container builds submit \
    --verbosity=debug \
    --timeout=${BUILD_TIMEOUT} \
    --config $ROOT_DIR/cloudbuild-${BUILD_TYPE}.yaml \
    --substitutions ${SUBSTITUTIONS_STRING} \
    ${TMPDIR}/docker-source.tar.gz && \
    rm -fr ${TMPDIR}
fi
