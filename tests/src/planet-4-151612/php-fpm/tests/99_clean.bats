#!/usr/bin/env bats
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "docker-compose nginx/php-fpm application container cleans up" {
  run clean_docker_compose
  [ $status -eq 0 ]
}
