#!/usr/bin/env bash
set -e

switches=("$@")

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
FILE_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
export FILE_DIR

. ${FILE_DIR}/env
. ${FILE_DIR}/helpers

for project_dir in ${FILE_DIR}/src/*/
do
  project=$(basename ${project_dir})
  for image_dir in ${project_dir}/*/
  do
    image=$(basename ${image_dir})
    >&2 echo -e "\n >> ${project}/${image}:${IMAGE_TAG}"
    export BATS_IMAGE=${image}
    export BATS_PROJECT_ID=${project}
    if [[ -d "${image_dir}/tests" ]]
    then
      bats "${switches[@]}" ${image_dir}/tests
    else
      >&2 echo "WARNING: ${image_dir} contains no tests!"
    fi

  done
done
