#!/usr/bin/env bats
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "container cleans up" {
  skip "testing"
  run clean_docker_compose "${compose_file}"
  [[ "$status" -eq 0 ]]
}
