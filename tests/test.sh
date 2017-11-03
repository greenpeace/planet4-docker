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


# Configure test output directory
if [[ -z ${TEST_OUTPUT_DIR} ]]
then

  TMPDIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")
  TEST_OUTPUT_DIR="${TMPDIR}/test-results"
  echo "Test output directory: $TEST_OUTPUT_DIR"
fi

mkdir -p "${TEST_OUTPUT_DIR}"

bats "${bats_switches[@]}" "${TEST_BASE_DIR}/self" | tee "${TEST_OUTPUT_DIR}/self.tap"

# Testing main project suite
shopt -s nullglob
# Iterate over all projects in src
for project_dir in ${TEST_BASE_DIR}/src/*/
do
  project_name="$(basename "${project_dir}")"
  # Iterate over all container images in the project
  for image_dir in ${project_dir}/*/
  do
    # Check if this project contains tests
    tests=($(find "${image_dir}tests" -maxdepth 1 -name "*.bats"))
    if [[ ${#tests[@]} -gt 0 ]]
    then
      # Run bats tests, piping output to file
      bats "${bats_switches[@]}" "${image_dir}tests" | tee "${TEST_OUTPUT_DIR}/${project_name}_$(basename "${image_dir}").tap"
    else
      warning "${image_dir} contains no tests!"
    fi
  done

  type -P tap-xunit >/dev/null 2>&1 || { warning "tap-xunit not found in path, skipping conversion..."; continue; }

  set -x

  echo "Converting results from TAP to xUnit format"
  for i in $TEST_OUTPUT_DIR/*.tap
  do
    filename="$(basename "$i")"
    # Convert .tap file to .xml
    tap-xunit > "${TEST_OUTPUT_DIR}/${filename%%\.*}.xml" < "${i}"

    # Strip all after first period
    clean_filename="${filename%%\.*}"
    # Replace underscore with forward slash
    image="${clean_filename//_//}"

    # Replace name attribute with something meaningful
    sed -i -e "s:name=\"Default\":name=\"${image}\":" "${TEST_OUTPUT_DIR}/${clean_filename}.xml"
  done

  type -P junit-merge >/dev/null 2>&1 || { warning "junit-merge not found in path, skipping merge"; continue; }

  echo "Merging xUnit results to: ${TEST_OUTPUT_DIR}/_test_results_merged.xml"
  mkdir -p ${TEST_OUTPUT_DIR}/merged
  junit-merge -d "${TEST_OUTPUT_DIR}" -o "${TEST_OUTPUT_DIR}/merged/test_results_merged.xml"

done
