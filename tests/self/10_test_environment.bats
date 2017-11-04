#!/usr/bin/env bash
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "ack exists and is executable" {
  if [[ ! -x "$(type -P ack)" ]]
  then
    >&2 echo "FATAL: ack not found"
    >&2 echo "Please download and install ack from https://beyondgrep.com/"
    exit 1
  fi
}

@test "shellcheck all Bash scripts" {
  run shellcheck_all_bash_scripts
  # We don't care bout failures here, just log them for future reference
  if [[ $status -ne 0 ]]
  then
    echo "${output}" > "${ARTIFACT_LOGS_DIR:-/tmp/artifacts/logs}/shellcheck.txt"
  fi
}
