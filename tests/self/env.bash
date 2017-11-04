#!/usr/bin/env bash
set -a

PROJECT_ROOT_DIR="${BATS_TEST_DIRNAME}/../../"
PROJECT_ID="$(grep "PROJECT_ID=.*" "${PROJECT_ROOT_DIR}/tests/self/fixtures/config.test" | cut -d \" -f 2)"

# shellcheck source=/dev/null
. "${BATS_TEST_DIRNAME}/../_env"
# shellcheck source=/dev/null
. "${BATS_TEST_DIRNAME}/../_helpers"

# Override automatic image name for self-test
BATS_IMAGE="self"

function shellcheck_all_bash_scripts {
  set -ex
  trap finish EXIT

  files=$(ack --shell -l "" "${PROJECT_ROOT_DIR}")

  for i in $files
  do
    shellcheck $i
  done
}

export BATS_IMAGE
export PROJECT_ROOT_DIR
export PROJECT_ID

export -f shellcheck_all_bash_scripts
