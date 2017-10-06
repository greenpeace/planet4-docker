#!/usr/bin/env bash
set -xe

# Read configuration from config file

# Helper functions
function fatal() {
  echo -e "ERROR: $1" >&2
  exit 1
}

function usage {
  fatal "Usage: $0 [OPTION|OPTION2] ...
Build and test artifacts in this repository

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

# Consolidate variables
BASEIMAGE_VERSION=${BASEIMAGE_VERSION:-${DEFAULT_BASEIMAGE_VERSION}}
BUILD_LOCALLY=${BUILD_LOCALLY:-${DEFAULT_BUILD_LOCALLY}}
BUILD_NAMESPACE=${BUILD_NAMESPACE:-${DEFAULT_BUILD_NAMESPACE}}
BUILD_REMOTELY=${BUILD_REMOTELY:-${DEFAULT_BUILD_REMOTELY}}
BUILD_TAG=${BUILD_TAG:-$(git rev-parse --abbrev-ref HEAD)}
BUILD_TAG=${BUILD_TAG//[^a-zA-Z0-9]/-}
BUILD_TIMEOUT=${BUILD_TIMEOUT:-${DEFAULT_BUILD_TIMEOUT}}
COMPOSER=${COMPOSER:-${DEFAULT_COMPOSER}}
CONTAINER_TIMEZONE=${CONTAINER_TIMEZONE:-$DEFAULT_CONTAINER_TIMEZONE}
DOCKERIZE_VERSION=${DOCKERIZE_VERSION:-$DEFAULT_DOCKERIZE_VERSION}
GIT_REF=${GIT_REF:-${DEFAULT_GIT_REF}}
GIT_SOURCE=${GIT_SOURCE:-${DEFAULT_GIT_SOURCE}}
GOOGLE_PROJECT_ID=${GOOGLE_PROJECT_ID:-${DEFAULT_GOOGLE_PROJECT_ID}}
HEADERS_MORE_VERSION=${HEADERS_MORE_VERSION:-${DEFAULT_HEADERS_MORE_VERSION}}
NGINX_PAGESPEED_RELEASE=${NGINX_PAGESPEED_RELEASE:-${DEFAULT_NGINX_PAGESPEED_RELEASE}}
NGINX_PAGESPEED_VERSION=${NGINX_PAGESPEED_VERSION:-${DEFAULT_NGINX_PAGESPEED_VERSION}}
NGINX_VERSION=${NGINX_VERSION:-${DEFAULT_NGINX_VERSION}}
OPENSSL_VERSION=${OPENSSL_VERSION:-${DEFAULT_OPENSSL_VERSION}}
PHP_MAJOR_VERSION=${PHP_MAJOR_VERSION:-${DEFAULT_PHP_MAJOR_VERSION}}
REVISION_TAG=${REVISION_TAG:-$(git rev-parse --short HEAD)}
REWRITE_LOCAL_DOCKERFILES=${REWRITE_LOCAL_DOCKERFILES:-${DEFAULT_REWRITE_LOCAL_DOCKERFILES}}
SOURCE_TAG=${SOURCE_TAG:-$(git rev-parse --abbrev-ref HEAD)}
SOURCE_TAG=${SOURCE_TAG//[^a-zA-Z0-9]/-}

# Get all the project subdirectories
ROOT_DIR=$(pwd)
shopt -s nullglob
cd "${ROOT_DIR}/source/${GOOGLE_PROJECT_ID}"
SOURCE_DIRECTORY=(*/)
cd "${ROOT_DIR}"
shopt -u nullglob
if [ "${REWRITE_LOCAL_DOCKERFILES}" = "true" ]; then

  for IMAGE in "${SOURCE_DIRECTORY[@]}"
  do
    echo -e "->> ${GOOGLE_PROJECT_ID}/${IMAGE}"

    IMAGE=${IMAGE%/}

    # Check the source directory exists and contains a Dockerfile template
    if [ ! -d "${ROOT_DIR}/source/${GOOGLE_PROJECT_ID}/${IMAGE}/templates" ]; then
      fatal "ERROR :: Directory not found: source/${GOOGLE_PROJECT_ID}/${IMAGE}/templates/"
    fi
    if [ ! -f "${ROOT_DIR}/source/${GOOGLE_PROJECT_ID}/${IMAGE}/templates/Dockerfile.in" ]; then
      fatal "ERROR :: Dockerfile not found: source/${GOOGLE_PROJECT_ID}/${IMAGE}/templates/Dockerfile.in"
    fi
    if [ ! -f "${ROOT_DIR}/source/${GOOGLE_PROJECT_ID}/${IMAGE}/templates/README.md.in" ]; then
      fatal "ERROR :: README not found: source/${GOOGLE_PROJECT_ID}/${IMAGE}/templates/README.md.in"
    fi

    BUILD_DIR="${ROOT_DIR}/source/${GOOGLE_PROJECT_ID}/${IMAGE}"

    # Rewrite cloudbuild variables
    ENVVARS=(
      '${BASEIMAGE_VERSION}' \
      '${BUILD_NAMESPACE}' \
      '${DOCKERIZE_VERSION}' \
      '${GOOGLE_PROJECT_ID}' \
      '${HEADERS_MORE_VERSION}'\
      '${NGINX_PAGESPEED_RELEASE}' \
      '${NGINX_PAGESPEED_VERSION}' \
      '${NGINX_VERSION}' \
      '${OPENSSL_VERSION}' \
      '${PHP_MAJOR_VERSION}' \
    )

    ENVVARS_STRING="$(printf "%s:" "${ENVVARS[@]}")"
    ENVVARS_STRING="${ENVVARS_STRING%:}"

    envsubst "${ENVVARS_STRING}" < ${BUILD_DIR}/templates/Dockerfile.in > ${BUILD_DIR}/Dockerfile
    envsubst "${ENVVARS_STRING}" < ${BUILD_DIR}/templates/README.md.in > ${BUILD_DIR}/README.md

    BUILD_STRING="# Planet4 Docker Application Stack
# Build: ${CIRCLE_BUILD_NUM:-"test-build"}
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in"

    echo -e "$BUILD_STRING\n$(cat ${BUILD_DIR}/Dockerfile)" > ${BUILD_DIR}/Dockerfile

  done
fi

# Perform the build locally
if [ "${BUILD_LOCALLY}" = "true" ]; then

  # Need to explicitly define build order for local directories
  # cloudbuild.yaml defines a logical build structure but local is alphanumeric
  LOCAL_BUILD_ORDER=(
    "ubuntu"
    "nginx-pagespeed"
    "nginx-php-exim"
    "wordpress"
    "p4-onbuild"
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
      -t ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${REVISION_TAG} \
      ${BUILD_DIR}
  done
fi

if [ "${BUILD_REMOTELY}" = "true" ]; then
  echo "Sending build context to Google Container Builder ..."

  # Rewrite cloudbuild variables
  SUBSTITUTIONS=(
    "_BASEIMAGE_VERSION=${BASEIMAGE_VERSION}" \
    "_BUILD_NAMESPACE=${BUILD_NAMESPACE}" \
    "_BUILD_TAG=${BUILD_TAG}" \
    "_CONTAINER_TIMEZONE=${CONTAINER_TIMEZONE}" \
    "_GOOGLE_PROJECT_ID=${GOOGLE_PROJECT_ID}" \
    "_HEADERS_MORE_VERSION=${HEADERS_MORE_VERSION}" \
    "_NGINX_PAGESPEED_RELEASE=${NGINX_PAGESPEED_RELEASE}" \
    "_NGINX_PAGESPEED_VERSION=${NGINX_PAGESPEED_VERSION}" \
    "_NGINX_VERSION=${NGINX_VERSION}" \
    "_OPENSSL_VERSION=${OPENSSL_VERSION}" \
    "_REVISION_TAG=${REVISION_TAG}" \
    "_SOURCE_TAG=${SOURCE_TAG}"
  )

  SUBSTITUTIONS_PROCESSOR="$(printf "%s," "${SUBSTITUTIONS[@]}")"
  SUBSTITUTIONS_STRING="${SUBSTITUTIONS_PROCESSOR%,}"

  # Avoid sending entire .git history as build context to save some time and bandwidth
  # Since git builtin substitutions aren't available unless triggered
  # https://cloud.google.com/container-builder/docs/concepts/build-requests#substitutions
  TMPDIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")
  tar --exclude='.git/' -zcf $TMPDIR/docker-source.tar.gz .

  # Check if we're running on CircleCI
  if [ ! -z "${CIRCLECI}" ]; then
    GCLOUD=/home/circleci/google-cloud-sdk/bin/gcloud
  else
    GCLOUD=gcloud
  fi

  # Submit the build
  time ${GCLOUD} container builds submit \
    --verbosity=debug \
    --timeout=${BUILD_TIMEOUT} \
    --config $ROOT_DIR/cloudbuild.yaml \
    --substitutions ${SUBSTITUTIONS_STRING} \
    ${TMPDIR}/docker-source.tar.gz && \
    rm -fr ${TMPDIR}
fi
