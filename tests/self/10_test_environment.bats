#!/usr/bin/env bash
set -e

load env

function setup {
  begin_output
  # Perform the build once only
  if [[ $BATS_TEST_NUMBER -eq 1 ]]
  then
    "${PROJECT_GIT_ROOT_DIR}/bin/build.sh" -c "${TEST_CONFIG_FILE}"
  fi
}

function teardown {
  store_output
}

@test "ack exists and is executable" {
  if [[ ! -x "$(type -P ack)" ]]
  then
    fatal "FATAL: ack not found.\nPlease install as per instructions at https://beyondgrep.com/"
  fi
}

@test "tap-xunit exists and is executable" {
  if [[ ! -x "$(type -P tap-xunit)" ]]
  then
    fatal "FATAL: tap-xunit not found.\nPlease install as per instructions at https://github.com/aghassemi/tap-xunit/releases"
    exit 1
  fi
}

@test "shellcheck exists and is executable" {
  if [[ ! -x "$(type -P shellcheck)" ]]
  then
    fatal "FATAL: shellcheck not found.\nPlease install as per instructions at https://www.shellcheck.net/"
    exit 1
  fi
}

@test "cgi-fcgi exists and is executable" {
  # Circle doesn't need this, the test relies on docker
  if [[ ${CIRCLECI} ]]
  then
    skip "CircleCI doesn't require cgi-fcgi binary"
  fi
  if [[ ! -x "$(type -P cgi-fcgi)" ]]
  then
    fatal "FATAL: cgi-fcgi not found.\nPlease install the 'fcgi' package from your operating system repository.\n E.g. brew install fcgi or apt-get install libfcgi0ldbl"
    exit 1
  fi
}

@test "shellcheck all Bash scripts" {
  run shellcheck_all_bash_scripts
  # We don't care bout failures here, just log them for future reference
  if [[ $status -ne 0 ]]
  then
    echo "${output}" > "${ARTIFACT_LOGS_DIR:-/tmp/artifacts/logs}"/shellcheck.txt
  fi
}

@test "build.sh exists and is executable" {
  [[ -f "${PROJECT_GIT_ROOT_DIR}/bin/build.sh" ]]
  [[ -x "${PROJECT_GIT_ROOT_DIR}/bin/build.sh" ]]
}

@test "build.sh prints usage information with -h flag" {
  run "${PROJECT_GIT_ROOT_DIR}/bin/build.sh" -h
  [[ $status -eq 0 ]]
  [[ $output =~ Usage ]]
}
