#!/usr/bin/env bash
set -ea

ARTIFACT_LOGS_DIR=${ARTIFACT_LOGS_DIR:-"/tmp/artifacts/logs"}
PROJECT_GIT_ROOT_DIR="${BATS_TEST_DIRNAME}/../.."
PROJECT_ID="$(grep "PROJECT_ID=.*" "${PROJECT_GIT_ROOT_DIR}/tests/self/fixtures/config.test" | cut -d \" -f 2)"
TEST_CONFIG_FILE="${PROJECT_GIT_ROOT_DIR}/tests/self/fixtures/config.test"

# shellcheck source=/dev/null
. "${BATS_TEST_DIRNAME}/../_env"
# shellcheck source=/dev/null
. "${BATS_TEST_DIRNAME}/../_helpers"

# Override automatic image name for self-test
BATS_IMAGE="self"

function shellcheck_all_bash_scripts {
  set -ex
  trap finish EXIT

  files=( "$(ack --shell -l "" "${PROJECT_GIT_ROOT_DIR}")" )

  for i in "${files[@]}"
  do
    shellcheck "$i"
  done
}

export ARTIFACT_LOGS_DIR
export BATS_IMAGE
export PROJECT_GIT_ROOT_DIR
export PROJECT_ID
export TEST_CONFIG_FILE

export -f shellcheck_all_bash_scripts
