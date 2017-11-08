#!/usr/bin/env bash
# shellcheck disable=SC2016

set -eo pipefail

# DEFAULT CONFIGURATION
# Read parameters from key->value configuration files
# Note this will override environment variables at this stage
# @todo prioritise ENV over config file ?

DEFAULT_CONFIG_FILE="./config.default"
if [ -f "${DEFAULT_CONFIG_FILE}" ]; then
  # shellcheck source=/dev/null
  source ${DEFAULT_CONFIG_FILE}
fi

# Need to explicitly define build order for local directories
# cloudbuild.yaml defines a logical build structure but local is alphanumeric
LOCAL_BUILD_ORDER=(
  "ubuntu"
  "nginx-pagespeed"
  "nginx-php-exim"
  "wordpress"
  "p4-onbuild"
)

# UTILITY

function usage {
  echo "Usage: $0 [OPTION|OPTION2] [<image build list>|all]...
Build and test artifacts in this repository

Options:
  -c    Configuration file for build variables, eg:
        $0 -c config
  -h    Print usage information (this text)
  -l    Perform the docker build locally (default: ${DEFAULT_BUILD_LOCALLY})
  -p    Pull created images after build
  -r    Perform the docker build remotely (default: ${DEFAULT_BUILD_REMOTELY})
  -v    Verbose output
"
}

function fatal() {
 echo -e "ERROR: $1" >&2
 exit 1
}

function containsElement() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

function sendBuildRequest() {
  local dir=${1:-${ROOT_DIR}}

  if [[ -f "$dir/cloudbuild.yaml" ]]
  then
    echo "Building from $dir"
  else
    fatal "No cloudbuild.yaml file found in $dir"
  fi

  # Check if we're running on CircleCI
  if [ ! -z "${CIRCLECI}" ]; then
    GCLOUD=/home/circleci/google-cloud-sdk/bin/gcloud
  else
    GCLOUD=$(type -P gcloud)
  fi

  if [[ ! -x ${GCLOUD} ]]
  then
    fatal "gcloud executable not found"
  fi

  # Rewrite cloudbuild variables
  local sub_array=(
    "_BUILD_NUM=${BUILD_NUM}"
    "_BUILD_NAMESPACE=${BUILD_NAMESPACE}" \
    "_BUILD_TAG=${BUILD_TAG}" \
    "_GOOGLE_PROJECT_ID=${GOOGLE_PROJECT_ID}" \
    "_REVISION_TAG=${REVISION_TAG}" \
  )

  sub="$(printf "%s," "${sub_array[@]}")"
  sub="${sub%,}"

  # Avoid sending entire .git history as build context to save some time and bandwidth
  # Since git builtin substitutions aren't available unless triggered
  # https://cloud.google.com/container-builder/docs/concepts/build-requests#substitutions
  TMPDIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")
  tar --exclude='.git/' --exclude='.circleci/' -zcf $TMPDIR/docker-source.tar.gz -C $dir .

  # Submit the build
  time ${GCLOUD} container builds submit \
    --verbosity=${VERBOSITY:-'warning'} \
    --timeout=${BUILD_TIMEOUT} \
    --config $dir/cloudbuild.yaml \
    --substitutions ${sub} \
    ${TMPDIR}/docker-source.tar.gz

  # Cleanup temporary file
  rm -fr ${TMPDIR}
}

# COMMAND LINE OPTIONS

OPTIONS=':vc:lhpr'
while getopts $OPTIONS option
do
    case $option in
        c  )    CONFIG_FILE=$OPTARG;;
        l  )    BUILD_LOCALLY='true';;
        h  )    usage
                exit;;
        p  )    PULL_IMAGES='true';;
        r  )    BUILD_REMOTELY='true';;
        v  )    VERBOSITY='debug'
                set -x;;
        *  )    echo "Unkown option: ${OPTARG}"
                usage;;
    esac
done
shift $((OPTIND - 1))

# ----------------------------------------------------------------------------
# If there are command line arguments, these are treated as subset build items
# instead of building the entire suite

if [[ $# -gt 0 ]] && [[ $1 != 'all' ]]
then
  echo "Building subset: " "$@"
  build_type='subset'
  build_list=($@)
else
  echo "Building all images"
  build_type='all'
  build_list=(${LOCAL_BUILD_ORDER[@]})
fi

# ----------------------------------------------------------------------------
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

# ----------------------------------------------------------------------------
# Consolidate and sanitise variables

APPLICATION_NAME=${APPLICATION_NAME:-${DEFAULT_APPLICATION_NAME}}
BASEIMAGE_VERSION=${BASEIMAGE_VERSION:-${DEFAULT_BASEIMAGE_VERSION}}
BRANCH_NAME=${CIRCLE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}
BRANCH_NAME=${BRANCH_NAME//[^a-zA-Z0-9\._-]/-}
BUILD_LOCALLY=${BUILD_LOCALLY:-${DEFAULT_BUILD_LOCALLY}}
BUILD_NAMESPACE=${BUILD_NAMESPACE:-${DEFAULT_BUILD_NAMESPACE}}
BUILD_REMOTELY=${BUILD_REMOTELY:-${DEFAULT_BUILD_REMOTELY}}
BUILD_NUM=${BUILD_NUM:-"test-${USER}-$(hostname -s)"}
BUILD_NUM=${BUILD_NUM//[^a-zA-Z0-9\._-]/-}
BUILD_TAG=${BUILD_TAG:-${BRANCH_NAME}}
BUILD_TAG=${BUILD_TAG//[^a-zA-Z0-9\._-]/-}
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
PULL_IMAGES=${PULL_IMAGES:-${DEFAULT_PULL_IMAGES}}
REVISION_TAG=${REVISION_TAG:-$(git rev-parse --short HEAD)}
REWRITE_LOCAL_DOCKERFILES=${REWRITE_LOCAL_DOCKERFILES:-${DEFAULT_REWRITE_LOCAL_DOCKERFILES}}
SOURCE_VERSION=${SOURCE_VERSION:-${BRANCH_NAME}}
SOURCE_VERSION=${SOURCE_VERSION//[^a-zA-Z0-9\._-]/-}

# ----------------------------------------------------------------------------
# Get all the project subdirectories

# Find real file path of current script
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
source="${BASH_SOURCE[0]}"
while [[ -h "$source" ]]
do # resolve $source until the file is no longer a symlink
  dir="$( cd -P "$( dirname "$source" )" && pwd )"
  source="$(readlink "$source")"
  [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
ROOT_DIR="$( cd -P "$( dirname "$source" )" && pwd )"

shopt -s nullglob
cd "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}"
SOURCE_DIRECTORY=(*/)
cd "${ROOT_DIR}"
shopt -u nullglob

# ----------------------------------------------------------------------------
# Update local Dockerfiles from template

if [ "${REWRITE_LOCAL_DOCKERFILES}" = "true" ]; then
  echo "Updating local Dockerfiles from templates..."
  for IMAGE in "${SOURCE_DIRECTORY[@]}"
  do
    IMAGE=${IMAGE%/}
    echo -e "->> ${GOOGLE_PROJECT_ID}/${IMAGE}"

    # Check the source directory exists and contains a Dockerfile template
    if [ ! -d "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${IMAGE}/templates" ]; then
      fatal "Directory not found: src/${GOOGLE_PROJECT_ID}/${IMAGE}/templates/"
    fi
    if [ ! -f "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${IMAGE}/templates/Dockerfile.in" ]; then
      fatal "Dockerfile not found: src/${GOOGLE_PROJECT_ID}/${IMAGE}/templates/Dockerfile.in"
    fi
    if [ ! -f "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${IMAGE}/templates/README.md.in" ]; then
      fatal "README not found: src/${GOOGLE_PROJECT_ID}/${IMAGE}/templates/README.md.in"
    fi

    BUILD_DIR="${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${IMAGE}"

    # Rewrite only the cloudbuild variables we want to change
    ENVVARS=(
      '${BASEIMAGE_VERSION}' \
      '${BUILD_NAMESPACE}' \
      '${CONTAINER_TIMEZONE}' \
      '${DOCKERIZE_VERSION}' \
      '${GOOGLE_PROJECT_ID}' \
      '${HEADERS_MORE_VERSION}'\
      '${NGINX_PAGESPEED_RELEASE}' \
      '${NGINX_PAGESPEED_VERSION}' \
      '${NGINX_VERSION}' \
      '${OPENSSL_VERSION}' \
      '${PHP_MAJOR_VERSION}' \
      '${SOURCE_VERSION}' \
    )

    ENVVARS_STRING="$(printf "%s:" "${ENVVARS[@]}")"
    ENVVARS_STRING="${ENVVARS_STRING%:}"

    envsubst "${ENVVARS_STRING}" < ${BUILD_DIR}/templates/Dockerfile.in > ${BUILD_DIR}/Dockerfile
    envsubst "${ENVVARS_STRING}" < ${BUILD_DIR}/templates/README.md.in > ${BUILD_DIR}/README.md

    BUILD_STRING="# ${APPLICATION_NAME}
# Build: ${BUILD_NUM}
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------
"

    echo -e "$BUILD_STRING\n$(cat ${BUILD_DIR}/Dockerfile)" > ${BUILD_DIR}/Dockerfile

  done
fi

# ----------------------------------------------------------------------------
# Perform the build locally

if [ "${BUILD_LOCALLY}" = "true" ]; then

  for IMAGE in "${LOCAL_BUILD_ORDER[@]}"; do

    if [[ ! $(containsElement "${IMAGE}" "${build_list[@]}") ]]
    then
      echo "Skipping ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE} as it was not listed as a command line argument"
      continue
    fi

    # Check the source directory exists and contains a Dockerfile
    if [ -d "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${IMAGE}" ] && [ -f "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${IMAGE}/Dockerfile" ]; then
      BUILD_DIR="${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${IMAGE}"
    elif [ -d "${ROOT_DIR}/sites/${GOOGLE_PROJECT_ID}/${IMAGE}" ] && [ -f "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${IMAGE}/Dockerfile" ]; then
      BUILD_DIR="${ROOT_DIR}/sites/${GOOGLE_PROJECT_ID}/${IMAGE}"
    else
      fatal "Dockerfile not found. Tried:\n - ./src/${GOOGLE_PROJECT_ID}/${IMAGE}/Dockerfile\n - ./sites/${GOOGLE_PROJECT_ID}/${IMAGE}/Dockerfile"
    fi

    echo -e "\nBuilding ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BUILD_TAG} ...\n"
    docker build \
      -t ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BUILD_TAG} \
      -t ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${REVISION_TAG} \
      ${BUILD_DIR}
  done
fi

# ----------------------------------------------------------------------------
# Send build requests to Google Container Builder

if [ "${BUILD_REMOTELY}" = "true" ]; then
  echo "Sending build context to Google Container Builder ..."

  if [[ "$build_type" = 'all' ]]
  then
    sendBuildRequest
  else
    for image in "${build_list[@]}"
    do
      sendBuildRequest "${ROOT_DIR}/src/$GOOGLE_PROJECT_ID/$image"
    done
  fi
fi

# ----------------------------------------------------------------------------
# Pull any newly built images, forking to background for parallel downloads

if [[ "${PULL_IMAGES}" = "true" ]]
then
  for IMAGE in "${build_list[@]}"
  do
    IMAGE=${IMAGE%/}
    echo -e "Pull ->> ${GOOGLE_PROJECT_ID}/${IMAGE}"
    docker pull "${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BUILD_TAG}" &
  done
fi

# ----------------------------------------------------------------------------
# Rewrite README.md variables

# shellcheck disable=SC2034
# Ignore tags for codacy branch badge
CIRCLE_BADGE_BRANCH=${BRANCH_NAME//\//%2F}

# Try to determine which branch we're on
CODACY_BRANCH_NAME=${CIRCLE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}
CODACY_BRANCH_NAME=${CODACY_BRANCH_NAME//[^[:alnum:]\._\/-]/-}
CODACY_BRANCH_NAME=${CODACY_BRANCH_NAME//\//%2F}

ENVVARS=(
  '${CIRCLE_BADGE_BRANCH}' \
  '${CODACY_BRANCH_NAME}' \
)

ENVVARS_STRING="$(printf "%s:" "${ENVVARS[@]}")"
ENVVARS_STRING="${ENVVARS_STRING%:}"

envsubst "${ENVVARS_STRING}" < ./README.md.in > ./README.md

wait # Until any docker pull requests have completed
