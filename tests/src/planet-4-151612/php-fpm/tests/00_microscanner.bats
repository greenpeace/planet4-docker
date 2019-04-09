#!/usr/bin/env bats
set -e

load env

@test "microscanner" {
  docker run --rm "$image" /microscanner ${MICROSCANNER_TOKEN}
}
