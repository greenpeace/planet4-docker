#!/usr/bin/env bash
# shellcheck disable=1090,2016
set -eou pipefail

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
GIT_ROOT_DIR="$( cd -P "$( dirname "$source" )/.." && pwd )"
export GIT_ROOT_DIR


# ----------------------------------------------------------------------------

# UTILITY

function usage {
  echo "Usage: $(basename "$0") [OPTION|OPTION2] [<image build list>|all]...
Build and test artifacts in this repository

Options:
  -c    Configuration file for build variables, eg:
          $(basename "$0") -c config
  -h    Help information (this text)
  -l    Local docker build
  -p    Pull images after build
  -r    Remote docker build on Google Container Registry
  -v    Verbose output
"
}

# COMMAND LINE OPTIONS

OPTIONS=':vc:lhpr'
while getopts $OPTIONS option
do
    case $option in
        c  )    # shellcheck disable=SC2034
                CONFIG_FILE=$OPTARG;;
        l  )    BUILD_LOCALLY=true;;
        h  )    usage
                exit 0;;
        p  )    PULL_IMAGES=true;;
        r  )    BUILD_REMOTELY=true;;
        v  )    verbosity=debug
                _verbose_debug on;;
        *  )    echo "Unkown option: ${OPTARG}"
                usage
                exit 1;;
    esac
done
shift $((OPTIND - 1))

. "${GIT_ROOT_DIR}/bin/inc/main"

# ----------------------------------------------------------------------------

function sendBuildRequest() {
  local dir=${1:-${GIT_ROOT_DIR}}

  if [[ -f "$dir/cloudbuild.yaml" ]]
  then
    _build "Building from $dir"
  else
    _fatal "No cloudbuild.yaml file found in $dir"
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

  tar --exclude='.git/' --exclude='.circleci/' -zcf "$BUILD_TMPDIR/docker-source.tar.gz" -C "$dir" .

  # Submit the build
  time "${gcloud_binary}" container builds submit \
    --verbosity="${verbosity:-warning}" \
    --timeout="${BUILD_TIMEOUT}" \
    --config "$dir/cloudbuild.yaml" \
    --substitutions "${sub}" \
    "${BUILD_TMPDIR}/docker-source.tar.gz"

}

# ----------------------------------------------------------------------------
# Check if we're running on CircleCI
if [[ ! -z "${CIRCLECI:-}" ]]
then
  # FIXME add the gcloud binary in planet4-base to PATH
  gcloud_binary=/home/circleci/google-cloud-sdk/bin/gcloud
else
  gcloud_binary="$(type -P gcloud)"
fi

if [[ ! -x "${gcloud_binary}" ]]
then
  _fatal "gcloud executable not found"
fi
# ----------------------------------------------------------------------------
# If the project has a custom build order, use that

declare -a build_order

if [[ -f "${GIT_ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/build_order" ]]
then
  _notice "Using build order from src/${GOOGLE_PROJECT_ID}/build_order"
  while read -r image_order; do
    # push line to build_order array
    _verbose "Adding to build order: '${image_order}'"
    build_order[${#build_order[@]}]="${image_order}"
  done < "${GIT_ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/build_order"
else
  build_order=(
    "ubuntu"
    "openresty"
    "php-fpm"
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

if [[ "${REWRITE_LOCAL_DOCKERFILES}" = "true" ]]
then
  _build "Generating files from templates:"
  for image in "${build_list[@]}"
  do


    # Check the source directory exists and contains a Dockerfile template
    if [ ! -d "${GIT_ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}/templates" ]; then
      _fatal "Directory not found: src/${GOOGLE_PROJECT_ID}/${image}/templates/"
    fi


    build_dir="${GIT_ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}"

    # Rewrite only the Dockerfile|README.md variables we want to change
    envvars=(
      '${APP_ENV}' \
      '${BASEIMAGE_VERSION}' \
      '${BUILD_NAMESPACE}' \
      '${CONTAINER_TIMEZONE}' \
      '${DOCKERIZE_VERSION}' \
      '${GOOGLE_PROJECT_ID}' \
      '${NGX_PAGESPEED_RELEASE}' \
      '${NGX_PAGESPEED_VERSION}' \
      '${OPENRESTY_VERSION}' \
      '${OPENSSL_VERSION}' \
      '${PHP_MAJOR_VERSION}' \
      '${SOURCE_VERSION}' \
    )

    envvars_string="$(printf "%s:" "${envvars[@]}")"
    envvars_string="${envvars_string%:}"

    if [[ -f "${GIT_ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}/templates/Dockerfile.in" ]]
    then
      _build " - ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}/Dockerfile"
      envsubst "${envvars_string}" < "${build_dir}/templates/Dockerfile.in" > "${build_dir}/Dockerfile"
      build_string="# ${APPLICATION_NAME}
# Image: ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}:${BUILD_TAG}
# Build: ${BUILD_NUM}
# Date:  $(date)
# ------------------------------------------------------------------------
# DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------
  "

      echo -e "$build_string\n$(cat "${build_dir}/Dockerfile")" > "${build_dir}/Dockerfile"
    else
      _warning "Dockerfile not found: src/${GOOGLE_PROJECT_ID}/${image}/templates/Dockerfile.in"
    fi

    if [[ -f "${GIT_ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}/templates/README.md.in" ]]
    then
      _build " - ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}/README.md"
      envsubst "${envvars_string}" < "${build_dir}/templates/README.md.in" > "${build_dir}/README.md"
    else
      _notice "README not found: src/${GOOGLE_PROJECT_ID}/${image}/templates/README.md.in"
    fi

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

envsubst "${ENVVARS_STRING}" < "${GIT_ROOT_DIR}/README.md.in" > "${GIT_ROOT_DIR}/README.md"

# ----------------------------------------------------------------------------
# Perform the build locally

if [[ "${BUILD_LOCALLY}" = "true" ]]
then
  _build "Performing build locally ..."
  for image in "${build_list[@]}"
  do

    # Check the source directory exists and contains a Dockerfile
    if [ -d "${GIT_ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}" ] && [ -f "${GIT_ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}/Dockerfile" ]; then
      build_dir="${GIT_ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}"
    elif [ -d "${GIT_ROOT_DIR}/sites/${GOOGLE_PROJECT_ID}/${image}" ] && [ -f "${GIT_ROOT_DIR}/src/${GOOGLE_PROJECT_ID}/${image}/Dockerfile" ]; then
      build_dir="${GIT_ROOT_DIR}/sites/${GOOGLE_PROJECT_ID}/${image}"
    else
      _fatal "Dockerfile not found. Tried:\n - ./src/${GOOGLE_PROJECT_ID}/${image}/Dockerfile\n - ./sites/${GOOGLE_PROJECT_ID}/${image}/Dockerfile"
    fi

    _build "${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}:${BUILD_TAG} ..."
    docker build \
      -t "${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}:${BUILD_TAG}" \
      -t "${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}:${REVISION_TAG}" \
      "${build_dir}"
  done
fi

# ----------------------------------------------------------------------------
# Send build requests to Google Container Builder

if [[ "${BUILD_REMOTELY}" = "true" ]]
then
  _build "Performing build on Google Container Builder:"

  if [[ "$build_type" = 'all' ]]
  then
    sendBuildRequest
  else
    for image in "${build_list[@]}"
    do
      _build " - ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}:${BUILD_TAG}"
      sendBuildRequest "${GIT_ROOT_DIR}/src/$GOOGLE_PROJECT_ID/$image"
    done
  fi
fi

# ----------------------------------------------------------------------------
# Pull any newly built images, forking to background for parallel downloads

if [[ "${PULL_IMAGES}" = "true" ]]
then
  for image in "${build_list[@]}"
  do
    _pull "${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}:${BUILD_TAG}"
    docker pull "${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${image}:${BUILD_TAG}" >/dev/null &
  done
fi

wait # Until any docker pull requests have completed
