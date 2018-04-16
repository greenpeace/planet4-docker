#!/usr/bin/env bash
set -eo pipefail

# UTILITY

function usage {
  echo "Usage: $0 [OPTION|OPTION2] ...
Build and test artifacts in this repository

Options:
  -c    Configuration file for build variables, eg:
          \$ $(basename "$0") -c config.custom
        Note that the file config.default is always loaded first and any
        key-value pairs in this custom configuration file overrides the defaults
  -h    Show usage (this information)
  -v    Verbose output
"
}

function fatal {
 echo -e "ERROR: $1" >&2
 exit 1
}

# COMMAND LINE OPTIONS

OPTIONS=':c:hv'
while getopts $OPTIONS option
do
    case $option in
        c  )    CONFIG_FILE=$OPTARG;;
        h  )    usage
                exit 0;;
        v  )    set -x;;
        *  )    >&2 echo "Unkown option: ${OPTARG}"
                usage
                exit 1;;
    esac
done
shift $((OPTIND - 1))

# CONFIG FILE
# Read parameters from key->value configuration files
# Note this will override environment variables at this stage
# @todo prioritise ENV over config file ?

DEFAULT_CONFIG_FILE="./config.default"
if [ -f "${DEFAULT_CONFIG_FILE}" ]; then
 # shellcheck source=./config.default
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

# Environment consolidation

BUILD_NAMESPACE=${BUILD_NAMESPACE}
BUILD_TAG=${BUILD_TAG:-"build-$CIRCLE_BUILD_NUM"}
GOOGLE_PROJECT_ID=${GOOGLE_PROJECT_ID}

# Get all the project subdirectories

GIT_ROOT_DIR=$(pwd)
shopt -s nullglob
cd "${GIT_ROOT_DIR}/src/${GOOGLE_PROJECT_ID}" || exit 1
SOURCE_DIRECTORY=(*/)
shopt -u nullglob


# Check if we're running on CircleCI
if [ ! -z "${CIRCLECI}" ]
then
  # Wrap with gcloud authenticated docker in container image
  DOCKER="${HOME}/google-cloud-sdk/bin/gcloud docker --"
else
  DOCKER="docker"
fi

for IMAGE in "${SOURCE_DIRECTORY[@]}"
do
  IMAGE=${IMAGE%/}

  ${DOCKER} pull ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BUILD_TAG}

  ${DOCKER} tag ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BUILD_TAG} ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:latest
  ${DOCKER} push ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:latest

  if [ ! -z "${CIRCLE_TAG}" ]
  then
    ${DOCKER} tag ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BUILD_TAG} ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${CIRCLE_TAG}
    ${DOCKER} push ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${CIRCLE_TAG}
  fi

done
