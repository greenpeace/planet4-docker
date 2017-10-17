#!/usr/bin/env bash
set -e

switches=("$@")

IMAGE_NAMESPACE=${BUILD_NAMESPACE:-"gcr.io"}
IMAGE_TAG=${BUILD_TAG:-${CIRCLE_TAG:-${CIRCLE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}}}
IMAGE_TAG=${IMAGE_TAG//[^a-zA-Z0-9]/-}

export IMAGE_TAG
export IMAGE_NAMESPACE

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
CURRENT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
export CURRENT_DIR

# shellcheck source=./helpers
. ${CURRENT_DIR}/helpers

for project_dir in ${CURRENT_DIR}/src/*/
do
  project=$(basename ${project_dir})
  for image_dir in ${project_dir}/*/
  do
    image=$(basename ${image_dir})
    >&2 echo " >> ${project}/${image}:${IMAGE_TAG}"
    export BATS_IMAGE=${image}
    export BATS_DIRECTORY=${image_dir}
    export BATS_PROJECT_ID=${project}
    for test in ${BATS_DIRECTORY}/tests/*.bats
    do
      bats "${switches[@]}" $test
    done
  done
done
