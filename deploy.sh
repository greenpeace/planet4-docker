#!/usr/bin/env bash
set -exo pipefail

# UTILITY

function usage {
  fatal "Usage: $0 [OPTION|OPTION2] ...
Build and test artifacts in this repository

Options:
  -c    Configuration file for build variables, eg:
        $0 -c config
  -v    Verbose output
"
}

function fatal {
 echo -e "ERROR: $1" >&2
 exit 1
}

# COMMAND LINE OPTIONS

OPTIONS=':vc:'
while getopts $OPTIONS option
do
    case $option in
        c  )    CONFIG_FILE=$OPTARG;;
        v  )    set -x;;
        *  )    echo "Unkown option: ${OPTARG}"
                usage;;
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

BUILD_NAMESPACE=${BUILD_NAMESPACE:-${DEFAULT_BUILD_NAMESPACE}}
BUILD_TAG=${BUILD_TAG:-"build-$CIRCLE_BUILD_NUM"}
GOOGLE_PROJECT_ID=${GOOGLE_PROJECT_ID:-${DEFAULT_GOOGLE_PROJECT_ID}}

# Get all the project subdirectories

ROOT_DIR=$(pwd)
shopt -s nullglob
cd "${ROOT_DIR}/src/${GOOGLE_PROJECT_ID}" || exit 1
SOURCE_DIRECTORY=(*/)
shopt -u nullglob

for IMAGE in "${SOURCE_DIRECTORY[@]}"
do
  IMAGE=${IMAGE%/}

  docker pull ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BUILD_TAG}
  docker tag ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BUILD_TAG} ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:latest
  docker push ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:latest

done
