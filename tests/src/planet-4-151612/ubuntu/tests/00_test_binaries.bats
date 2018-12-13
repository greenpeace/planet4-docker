#!/usr/bin/env bats
set -e

version_detect="[[:digit:]]+\\.[[:digit:]]+\\.[[:digit:]]+"

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "wget" {
  run run_docker_binary "$image" wget --version
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "Wget $version_detect"
}

@test "dockerize" {
  run run_docker_binary "$image" dockerize --version
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "v$version_detect"
}
