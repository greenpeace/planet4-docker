#!/usr/bin/env bash
set -eo pipefail

# UTILITY

function usage() {
  echo "Usage: $0 [OPTION|OPTION2] ...
Build and test artifacts in this repository

Options:
  -h    Show usage (this information)
  -v    Verbose output
"
}

function fatal() {
  echo -e "ERROR: $1" >&2
  exit 1
}

# COMMAND LINE OPTIONS

OPTIONS=':c:hv'
while getopts $OPTIONS option; do
  case $option in
    h)
      usage
      exit 0
      ;;
    v) set -x ;;
    *)
      echo >&2 "Unkown option: ${OPTARG}"
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

BUILD_TAG=${BUILD_TAG:-"build-$CIRCLE_BUILD_NUM"}

# Get all the project subdirectories

GIT_ROOT_DIR=$(pwd)
shopt -s nullglob
cd "${GIT_ROOT_DIR}/src/${GOOGLE_PROJECT_ID}" || exit 1
SOURCE_DIRECTORY=(*/)
shopt -u nullglob

gcloud auth configure-docker

for IMAGE in "${SOURCE_DIRECTORY[@]}"; do
  IMAGE=${IMAGE%/}

  docker pull ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BUILD_TAG}

  docker tag ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BUILD_TAG} ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:latest
  docker push ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:latest

  if [ ! -z "${CIRCLE_TAG}" ]; then
    docker tag ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BUILD_TAG} ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${CIRCLE_TAG}
    docker push ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${CIRCLE_TAG}
  fi

done
