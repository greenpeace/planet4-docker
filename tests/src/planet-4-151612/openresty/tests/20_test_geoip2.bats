#!/usr/bin/env bats
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "GEOIP - container starts" {
  run start_docker_compose "${BATS_TEST_DIRNAME}/../docker-compose.geoip.yml"
  [ $status -eq 0 ]
}

@test "GEOIP - 'Country: Unknown' in test output" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.geoip.yml" exec app curl localhost
  [ $status -eq 0 ]
  printf '%s' "$output" | grep "Country: Unknown"
}

@test "GEOIP - container cleans up" {
  run clean_docker_compose
  [ $status -eq 0 ]
}