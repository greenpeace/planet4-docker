#!/usr/bin/env bash
set -e

switches=("$@")

source="${BASH_SOURCE[0]}"
while [[ -h "$source" ]]
do # resolve $source until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$source" )" && pwd )"
  source="$(readlink "$source")"
  [[ $source != /* ]] && source="$DIR/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
file_dir="$( cd -P "$( dirname "$source" )" && pwd )"
export file_dir

# shellcheck source=./env
. ${file_dir}/env
# shellcheck source=./helpers
. ${file_dir}/helpers

for project_dir in ${file_dir}/src/*/
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
