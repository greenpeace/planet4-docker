#!/usr/bin/env bash
set -e

# Description:  Performs Bash Automated Shell Tests
#               Usage:
#               ./test.sh [directory] [Bats command line switches]
# Author:       Raymond Walker <raymond.walker@greenpeace.org>

# Find real file path of current script
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
source="${BASH_SOURCE[0]}"
while [[ -h "$source" ]]
do # resolve $source until the file is no longer a symlink
  dir="$( cd -P "$( dirname "$source" )" && pwd )"
  source="$(readlink "$source")"
  [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
TEST_BASE_DIR="$( cd -P "$( dirname "$source" )" && pwd )"
export TEST_BASE_DIR


# Include base project helper functions
# shellcheck source=/dev/null
. ${TEST_BASE_DIR}/_helpers

type -P bats >/dev/null 2>&1 || fatal "bats not found in path"

# Pass any command line parameters to bats
bats_switches=("$@")

# If first parameter is name of a directory, assume that's the test base
if [[ "$1" ]] && [[ -d ${TEST_BASE_DIR}/${1} ]]
then
  echo "Testing in: ./${1}"
  TEST_BASE_DIR="${TEST_BASE_DIR}/${1}"
  shift

  # Include any new helper functionality in this subdirectory
  if [[ -f ${TEST_BASE_DIR}/_helpers ]]
  then
    # shellcheck source=/dev/null
    . ${TEST_BASE_DIR}/_helpers
  fi

  bats "${bats_switches[@]}"

else
  echo "Performing self tests..."
  bats "${bats_switches[@]}" "${TEST_BASE_DIR}/self"

  # Testing main project suite
  echo "Testing in ./src"

  shopt -s nullglob
  for project_dir in ${TEST_BASE_DIR}/src/*/
  do
    for image_dir in ${project_dir}/*/
    do
      if [[ -d ${image_dir}/tests ]]
      then
        bats "${bats_switches[@]}" "${image_dir}/tests"
      else
        >&2 echo "WARNING: ${image_dir} contains no tests!"
      fi

    done
  done
fi
