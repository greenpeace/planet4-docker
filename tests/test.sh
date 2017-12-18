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
. "${TEST_BASE_DIR}/_helpers"

type -P bats >/dev/null 2>&1 || fatal "bats not found in path"

# Pass any command line parameters to bats
bats_switches=("$@")

# Configure test output directory
if [[ -z "${TEST_OUTPUT_DIR}" ]]
then
  TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")"
  TEST_OUTPUT_DIR="${TEST_TMPDIR}/test-results"
  echo "Test output directory: $TEST_OUTPUT_DIR"
fi

# Make directory if not exist
[[ ! -e "${TEST_OUTPUT_DIR}" ]] && mkdir -p "${TEST_OUTPUT_DIR}"
# Exit if not directory
[[ ! -d "${TEST_OUTPUT_DIR}" ]] && >&2 echo "Error: ${TEST_OUTPUT_DIR} is not a directory" && exit 1
# Exit if not writable
[[ ! -w "${TEST_OUTPUT_DIR}" ]] && >&2 echo "Error: ${TEST_OUTPUT_DIR} is not writable" && exit 1

bats "${bats_switches[@]}" "${TEST_BASE_DIR}/self" | tee "${TEST_OUTPUT_DIR}/self.tap"

# Ensure tap-xunit exists in path
if [[ $(type -P tap-xunit >/dev/null 2>&1) -ne 1 ]]
then
  # Convert .tap file to .xml
  tap-xunit > "${TEST_OUTPUT_DIR}/self.xml" < "${TEST_OUTPUT_DIR}/self.tap"
  # Replace name attribute with something meaningful
  sed -i -e "s:name=\"Default\":name=\"Self-test\":" "${TEST_OUTPUT_DIR}/self.xml"
fi

# Testing main project suite
# Iterate over all projects in src

shopt -s nullglob

for project_dir in "${TEST_BASE_DIR}"/src/*/
do
  declare -a test_order
  if [[ -f "${project_dir}/test_order" ]]
  then
    # read test order from file
    echo "Using test order from file: ${project_dir}/test_order"
    while read -r line; do
      echo " - ${line}"
      # array push line to test_order
      test_order[${#test_order[@]}]="${project_dir}${line}/"
    done < "${project_dir}/test_order"
  else
    # alphanumeric
    test_order=( "${project_dir}"*/ )
  fi

  for image_dir in "${test_order[@]}"
  do
    # Ensure the directory contains a 'tests' subdirectory
    if [[ ! -d "${image_dir}tests" ]]
    then
      warning "${image_dir} contains no tests!"
      continue
    fi

    # Ensure the tests subdirectory contains at least one .bats test file
    tests=($(find "${image_dir}tests" -maxdepth 1 -name "*.bats"))
    if [[ ${#tests[@]} -lt 1 ]]
    then
      warning "${image_dir} contains no tests!"
      continue
    fi

    filename="$(basename "${project_dir}")_$(basename "${image_dir}")"

    # Run bats tests, piping output to file
    bats "${bats_switches[@]}" "${image_dir}tests" | tee "${TEST_OUTPUT_DIR}/${filename}.tap"

    # Ensure tap-xunit exists in path
    type -P tap-xunit >/dev/null 2>&1 || { warning "tap-xunit not found in path, skipping conversion..."; continue; }

    # Convert .tap file to .xml
    tap-xunit > "${TEST_OUTPUT_DIR}/${filename}.xml" < "${TEST_OUTPUT_DIR}/${filename}.tap"

    # Replace underscore in filename with forward slash to suit image naming convention
    image="${filename//_//}"

    # Replace name attribute with something meaningful
    sed -i -e "s:name=\"Default\":name=\"${image}\":" "${TEST_OUTPUT_DIR}/${filename}.xml"
  done

  # Ensure junit-merge exists in path
  type -P junit-merge >/dev/null 2>&1 || { warning "junit-merge not found in path, skipping merge"; continue; }

  mkdir -p ${TEST_OUTPUT_DIR}/merged
  junit-merge -d "${TEST_OUTPUT_DIR}" -o "${TEST_OUTPUT_DIR}/merged/test_results_merged.xml"

done
shopt -u nullglob
