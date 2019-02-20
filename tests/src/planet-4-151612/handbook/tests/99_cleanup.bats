#!/usr/bin/env bats
set -e

load env

@test "container cleans up" {
  run clean_docker_compose "${compose_file}"
  [[ "$status" -eq 0 ]]
}
