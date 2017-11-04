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
    fatal "FATAL: ack not found.\nPlease download and install from https://beyondgrep.com/"
  fi
}

@test "tap-xunit exists and is executable" {
  if [[ ! -x "$(type -P tap-xunit)" ]]
  then
    fatal "FATAL: tap-xunit not found.\nPlease download and install from https://github.com/aghassemi/tap-xunit/releases"
    exit 1
  fi
}

@test "shellcheck exists and is executable" {
  if [[ ! -x "$(type -P shellcheck)" ]]
  then
    fatal "FATAL: shellcheck not found.\nPlease download and install from https://www.shellcheck.net/"
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
