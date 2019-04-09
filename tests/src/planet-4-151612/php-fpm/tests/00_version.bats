#!/usr/bin/env bats
set -e

load env

@test "php --version" {
  run run_docker_binary "$image" php --version
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "PHP [[:digit:]]+\\.[[:digit:]]+\\.[[:digit:]]+"
}

@test "composer --version" {
  run run_docker_binary "$image" composer --no-ansi --version
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "Composer version [[:digit:]]+\\.[[:digit:]]+"
}
