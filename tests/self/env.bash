#!/usr/bin/env bash
set -a

# shellcheck source=/dev/null
PROJECT_ROOT_DIR="${BATS_TEST_DIRNAME}/../../"

# shellcheck source=/dev/null
. "${BATS_TEST_DIRNAME}/../_env"
# shellcheck source=/dev/null
. "${BATS_TEST_DIRNAME}/../_helpers"

function shellcheck_all_bash_scripts {
  set -ex
  trap finish EXIT

  ack --shell -l "" "${PROJECT_ROOT_DIR}"
}

export PROJECT_ROOT_DIR

export -f shellcheck_all_bash_scripts
