#!/usr/bin/env bash
# shellcheck disable=SC2016

set -eo pipefail

# ----------------------------------------------------------------------------
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

# DEFAULT CONFIGURATION
# Read parameters from key->value configuration files
# Note this will override environment variables at this stage
# @todo prioritise ENV over config file ?

DEFAULT_CONFIG_FILE="${ROOT_DIR}/config.default"
if [ -f "${DEFAULT_CONFIG_FILE}" ]; then
  # shellcheck source=/dev/null
  source ${DEFAULT_CONFIG_FILE}
fi

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

if test -t 1; then

    # Check that it supports colours
    ncolors=$(tput colors)

    if test -n "$ncolors" && test $ncolors -ge 8; then
        bold="$(tput bold)"
        underline="$(tput smul)"
        standout="$(tput smso)"
        normal="$(tput sgr0)"
        black="$(tput setaf 0)"
        red="$(tput setaf 1)"
        green="$(tput setaf 2)"
        yellow="$(tput setaf 3)"
        blue="$(tput setaf 4)"
        magenta="$(tput setaf 5)"
        cyan="$(tput setaf 6)"
        white="$(tput setaf 7)"
    fi
fi

function _fatal() {
 _out "${bold:-''}${red:-''} [ERROR]${normal:-''}" "$1" >&2
 exit 1
}

function _out() {
  local type
  local text
  type=$1

  shift
  text=$*

  printf "%s %s\n" "$type" "$text"
}

function _notice {
  _out "${white:-''}[NOTICE]${white:-''}" "$@"
}

function _skip() {
  _out "${cyan:-''}  [SKIP]${normal:-''}" "$@"
}

function _build() {
  _out "${green:-''} [BUILD]${normal:-''}" "$@"
}

function _pull() {
  _out "${green:-''}  [PULL]${normal:-''}" "$@"
}

function _verbose() {
  if [[ $verbosity != 'verbose' ]]
  then
    return
  fi
  _out "${green:-''}  [PULL]${normal:-''}" "$@"
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
    _notice "Building from $dir"
  else
    _fatal "No cloudbuild.yaml file found in $dir"
  fi

  # Check if we're running on CircleCI
  if [ ! -z "${CIRCLECI}" ]; then
    gcloud_binary=/home/circleci/google-cloud-sdk/bin/gcloud
  else
    gcloud_binary=$(type -P gcloud)
  fi

  if [[ ! -x ${gcloud_binary} ]]
  then
    _fatal "gcloud executable not found"
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
  local tmpdir
  tmpdir=$(mktemp -d "${tmpdir:-/tmp/}$(basename 0).XXXXXXXXXXXX")
  tar --exclude='.git/' --exclude='.circleci/' -zcf $tmpdir/docker-source.tar.gz -C $dir .

  # Submit the build
  time ${gcloud_binary} container builds submit \
    --verbosity=${verbosity:-'warning'} \
    --timeout=${BUILD_TIMEOUT} \
    --config $dir/cloudbuild.yaml \
    --substitutions ${sub} \
    ${tmpdir}/docker-source.tar.gz

  # Cleanup temporary file
  rm -fr ${tmpdir}
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
        v  )    verbosity='debug'
                set -x;;
        *  )    echo "Unkown option: ${OPTARG}"
                usage;;
    esac
done
shift $((OPTIND - 1))


# ----------------------------------------------------------------------------
# Read from custom config file from command line parameter

if [ "${CONFIG_FILE}" != "" ]; then
  echo "Reading custom configuration from ${CONFIG_FILE}"

  if [ ! -f "${CONFIG_FILE}" ]; then
    _fatal "File not found: ${CONFIG_FILE}"
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
# If the project has a custom build order, use that

declare -a build_order

if [[ -f "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/build_order" ]]
then
  _notice "Using build order from src/${GOOGLE_PROJECT_ID}/build_order"
  while read -r image_order; do
    # push line to build_order array
    _verbose "Adding to build order: '${image_order}'"
    build_order[${#build_order[@]}]="${image_order}"
  done < "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/build_order"
else
  build_order=(
    "ubuntu"
    "nginx-pagespeed"
    "nginx-php-exim"
    "wordpress"
    "p4-onbuild"
  )
fi

# ----------------------------------------------------------------------------
# If there are command line arguments, these are treated as subset build items
# instead of building the entire suite

if [[ $# -gt 0 ]] && [[ $1 != 'all' ]]
then
  _build "Building subset: "

  if [[ $1 =~ '+'$ ]]
  then
    build_start=${1%+}
    build_list=(${build_order[@]})
    i=0
    for build_image in "${build_order[@]}"
    do
      if [[ $build_image != "${build_start}" ]]
      then
        unset "build_list[$i]"
      else
        break
      fi
      i=$((i + 1))
    done

  else
    build_type='subset'
    build_list=($@)
  fi

  for i in "${build_list[@]}"
  do
    _build " - $i"
  done

else
  _notice "Building all images"
  build_type='all'
  build_list=(${build_order[@]})
fi

# ----------------------------------------------------------------------------
# Update local Dockerfiles from template

if [ "${REWRITE_LOCAL_DOCKERFILES}" = "true" ]; then
  _verbose "Updating local Dockerfiles from templates..."
  for image in "${build_list[@]}"
  do

    # Check the source directory exists and contains a Dockerfile template
    if [ ! -d "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}/templates" ]; then
      _fatal "Directory not found: src/${GOOGLE_PROJECT_ID}/${image}/templates/"
    fi
    if [ ! -f "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}/templates/Dockerfile.in" ]; then
      _fatal "Dockerfile not found: src/${GOOGLE_PROJECT_ID}/${image}/templates/Dockerfile.in"
    fi
    if [ ! -f "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}/templates/README.md.in" ]; then
      _fatal "README not found: src/${GOOGLE_PROJECT_ID}/${image}/templates/README.md.in"
    fi

    build_dir="${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}"

    # Rewrite only the Dockerfile|README.md variables we want to change
    envvars=(
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

    envvars_string="$(printf "%s:" "${envvars[@]}")"
    envvars_string="${envvars_string%:}"

    _verbose "Update ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}/Dockerfile from template"
    envsubst "${envvars_string}" < ${build_dir}/templates/Dockerfile.in > ${build_dir}/Dockerfile
    _verbose "Update ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}/README.md from template"
    envsubst "${envvars_string}" < ${build_dir}/templates/README.md.in > ${build_dir}/README.md

    build_string="# ${APPLICATION_NAME}
# Build: ${BUILD_NUM}
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------
"

    echo -e "$build_string\n$(cat ${build_dir}/Dockerfile)" > ${build_dir}/Dockerfile

  done
fi

# ----------------------------------------------------------------------------
# Perform the build locally

if [ "${BUILD_LOCALLY}" = "true" ]; then
  _build "Performing build locally ..."
  for image in "${build_order[@]}"; do

    if [[ ! $(containsElement "${image}" "${build_list[@]}") ]]
    then
      _skip "${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}"
      continue
    fi

    # Check the source directory exists and contains a Dockerfile
    if [ -d "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}" ] && [ -f "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}/Dockerfile" ]; then
      build_dir="${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}"
    elif [ -d "${ROOT_DIR}/sites/${GOOGLE_PROJECT_ID}/${image}" ] && [ -f "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}/Dockerfile" ]; then
      build_dir="${ROOT_DIR}/sites/${GOOGLE_PROJECT_ID}/${image}"
    else
      _fatal "Dockerfile not found. Tried:\n - ./src/${GOOGLE_PROJECT_ID}/${image}/Dockerfile\n - ./sites/${GOOGLE_PROJECT_ID}/${image}/Dockerfile"
    fi

    _build "${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}:${BUILD_TAG} ...\n"
    docker build \
      -t ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}:${BUILD_TAG} \
      -t ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}:${REVISION_TAG} \
      ${build_dir}
  done
fi

# ----------------------------------------------------------------------------
# Send build requests to Google Container Builder

if [ "${BUILD_REMOTELY}" = "true" ]; then
  _build "Performing build on Google Container Builder ..."

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
  for image in "${build_list[@]}"
  do
    _pull "${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}"
    docker pull "${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}:${BUILD_TAG}" &
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
