#!/usr/bin/env bats
set -e

load env

@test "container starts" {
  run docker-compose --no-ansi -p "$project" -f "${compose_file}" down
  # Start containers in the compose file
  run docker-compose --no-ansi -p "$project" -f "${compose_file}" up --remove-orphans -d
  [ $status -eq 0 ]
  run docker-compose --no-ansi -p "$project" -f "${compose_file}" exec mail \
    dockerize -wait tcp://localhost:25 -timeout 10s
  [ $status -eq 0 ]
}

@test "container cleans up" {
  run clean_docker_compose
  [ $status -eq 0 ]
}
