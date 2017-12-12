#!/usr/bin/env bash
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "deploy.sh exists and is executable" {
  [[ -f "${PROJECT_GIT_ROOT_DIR}/bin/deploy.sh" ]]
  [[ -x "${PROJECT_GIT_ROOT_DIR}/bin/deploy.sh" ]]
}

@test "deploy.sh prints usage information with -h flag" {
  run "${PROJECT_GIT_ROOT_DIR}/bin/deploy.sh" -h
  [[ $status -eq 0 ]]
  [[ $output =~ "usage" ]]
}
