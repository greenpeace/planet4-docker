#!/usr/bin/env bash
set -e

load env

function setup {
  begin_output
  run "${PROJECT_ROOT_DIR}/build.sh" -c "${TEST_CONFIG_FILE}"
}

function teardown {
  store_output
}

@test "build.sh exists and is executable" {
  [[ -f "${PROJECT_ROOT_DIR}/build.sh" ]]
  [[ -x "${PROJECT_ROOT_DIR}/build.sh" ]]
}

@test "build.sh prints usage information with -h flag" {
  run ${PROJECT_ROOT_DIR}/build.sh -h
  [[ $status -eq 0 ]]
  [[ $output =~ "usage" ]]
}
