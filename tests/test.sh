#!/usr/bin/env bash
set -eu

# Description:  Performs Bash Automated Shell Tests
#               Usage:
#               ./test.sh [directory] [Bats command line switches]
# Author:       Raymond Walker <raymond.walker@greenpeace.org>

# Find real file path of current script
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within

function usage() {
  echo "Test container artifacts

Usage: $(basename "$0") [-c <config-file>]

Options:
  -c    Configuration file, eg:
          $(basename "$0") -c config.example
"
}

# COMMAND LINE OPTIONS

OPTIONS=':vc:lhpr'
while getopts $OPTIONS option; do
  case $option in
    c) # shellcheck disable=SC2034
      CONFIG_FILE=$OPTARG ;;
    *)
      echo "Unkown option: ${OPTARG}"
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

source="${BASH_SOURCE[0]}"
while [[ -L "$source" ]]; do # resolve $source until the file is no longer a symlink
  dir="$(cd -P "$(dirname "$source")" && pwd)"
  source="$(readlink "$source")"
  [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
TEST_BASE_DIR="$(cd -P "$(dirname "$source")" && pwd)"
export TEST_BASE_DIR

echo "Config file: $TEST_BASE_DIR/../${CONFIG_FILE:-config.default}"
while read -r line; do
  [[ $line == "#"* ]] && continue
  [[ -z "$line" ]] && continue
  echo "$line"
  declare "$line"
done <"$TEST_BASE_DIR/../${CONFIG_FILE:-config.default}"

# Include base project helper functions
. "${TEST_BASE_DIR}/_helpers"

type -P bats >/dev/null 2>&1 || fatal "bats not found in path"

# Pass any command line parameters to bats
bats_switches=("$@")

# Configure test output directory
if [[ -z "${TEST_OUTPUT_DIR:-}" ]]; then
  TEST_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/XXXXXXXXXXXX")
  TEST_OUTPUT_DIR="${TEST_TMPDIR}/planet4-docker-output"
fi

# Make directory if not exist
[[ ! -e "${TEST_OUTPUT_DIR}" ]] && mkdir -p "${TEST_OUTPUT_DIR}"
# Exit if not directory
[[ ! -d "${TEST_OUTPUT_DIR}" ]] && echo >&2 "Error: ${TEST_OUTPUT_DIR} is not a directory" && exit 1
# Exit if not writable
[[ ! -w "${TEST_OUTPUT_DIR}" ]] && echo >&2 "Error: ${TEST_OUTPUT_DIR} is not writable" && exit 1

echo "Test output directory: $TEST_OUTPUT_DIR"

echo "--- self.tap"
# Run self tests
set +u
time bats "${bats_switches[@]}" "${TEST_BASE_DIR}/self" | tee "${TEST_OUTPUT_DIR}/self.tap"
set -u

# Ensure tap-xunit exists in path
if [[ $(type -P tap-xunit >/dev/null 2>&1) -ne 1 ]]; then
  # Convert .tap file to .xml
  tap-xunit >"${TEST_OUTPUT_DIR}/self.xml" <"${TEST_OUTPUT_DIR}/self.tap"
  # Replace name attribute with something meaningful
  sed -i -e "s:name=\"Default\":name=\"Self-test\":" "${TEST_OUTPUT_DIR}/self.xml"
fi

# Testing main project suite
# Iterate over all projects in src

shopt -s nullglob

test_folders="${TEST_FOLDERS:-${TEST_BASE_DIR}/src/${GOOGLE_PROJECT_ID}/}"
echo >&2 "Test folders: '${test_folders//"$(pwd)"/}'"

for project_dir in ./${test_folders//"$(pwd)"/}; do
  if [ ! -d "$project_dir" ]; then
    error "Test folder not found: $project_dir"
    exit 1
  fi

  declare -a test_order
  test_order=()
  if [[ -f "${project_dir}test_order" ]]; then
    # read test order from file
    echo "Using test order from file: ${project_dir//$(pwd)/}test_order"
    while read -r line; do
      echo " - ${line}"
      # array push line to test_order
      test_order+=("${project_dir}${line}/")
    done <"${project_dir}test_order"
  else
    echo "Test order not defined, using directory structure"
    # alphanumeric
    test_order=("${project_dir}"*/)
  fi

  for image_dir in "${test_order[@]}"; do
    # Ensure the directory contains a 'tests' subdirectory
    if [[ ! -d "${image_dir}tests" ]]; then
      echo "--- $(basename "${image_dir}")"
      warning "${image_dir}tests not found"
      continue
    fi

    # Ensure the tests subdirectory contains at least one .bats test file
    tests=($(find "${image_dir}tests" -maxdepth 1 -name "*.bats"))
    if [[ ${#tests[@]} -lt 1 ]]; then
      warning "${image_dir} contains no tests!"
      continue
    fi

    filename="$(basename "${project_dir}")_$(basename "${image_dir}")"

    echo "--- $(basename "${image_dir}").tap"
    # Run bats tests, piping output to file
    set +u
    time bats "${bats_switches[@]}" "${image_dir}tests" | tee "${TEST_OUTPUT_DIR}/${filename}.tap"
    set -u

    # Ensure tap-xunit exists in path
    type -P tap-xunit >/dev/null 2>&1 || {
      warning "tap-xunit not found in path, skipping conversion..."
      continue
    }

    # Convert .tap file to .xml
    tap-xunit >"${TEST_OUTPUT_DIR}/${filename}.xml" <"${TEST_OUTPUT_DIR}/${filename}.tap"

    # Replace underscore in filename with forward slash to suit image naming convention
    image="${filename//_//}"

    # Replace name attribute with something meaningful
    sed -i -e "s:name=\"Default\":name=\"${image}\":" "${TEST_OUTPUT_DIR}/${filename}.xml"

  done

  # Ensure junit-merge exists in path
  type -P junit-merge >/dev/null 2>&1 || {
    warning "junit-merge not found in path, skipping merge"
    continue
  }

  mkdir -p ${TEST_OUTPUT_DIR}/merged
  junit-merge -d "${TEST_OUTPUT_DIR}" -o "${TEST_OUTPUT_DIR}/merged/test_results_merged.xml"

done
shopt -u nullglob

echo "Test output directory: $TEST_OUTPUT_DIR"
