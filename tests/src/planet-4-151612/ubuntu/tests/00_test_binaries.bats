#!/usr/bin/env bats
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "wget" {
  run run_docker_binary "$image" wget --version
  [[ "$status" -eq 0 ]]
}

@test "dockerize" {
  run run_docker_binary "$image" dockerize --version
  [[ "$status" -eq 0 ]]
}
