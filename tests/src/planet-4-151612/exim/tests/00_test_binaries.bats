#!/usr/bin/env bats
set -e

version_detect="[[:digit:]]+\\.[[:digit:]]+"

load env

@test "exim --version" {
  run run_docker_binary "$image" exim --version
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "Exim version $version_detect"
}
