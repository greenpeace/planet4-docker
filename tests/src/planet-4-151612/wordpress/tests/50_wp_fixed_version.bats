#!/usr/bin/env bats
set -e

load env

export WP_VERSION=4.9.7

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "shutdown existing containers" {
  docker-compose -f "${compose_file}" down -v
}

@test "docker compose start $IMAGE_TAG" {
  # Wait up to 10 minutes for the build to complete!
  run start_docker_compose "${BATS_TEST_DIRNAME}/../docker-compose.yml" http://localhost:80 proxy 20
  [ $status -eq 0 ]
}

@test "wordpress version $WP_VERSION" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.yml" exec php-fpm wp core version
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "$WP_VERSION"
}

@test "responds on port 80 with status 200" {
  run curl_check_status_code 200 http://localhost:80 proxy 10
  [ $status -eq 0 ]
  [ $output -eq 200 ]
}

@test "response contains string greenpeace" {
  run curl_check_response_regex "greenpeace" http://localhost:80 proxy 5
  [ $status -eq 0 ]
}

@test "response does not contain string FNORDPTANGWIBBLE" {
  run curl_check_response_regex "FNORDPTANGWIBBLE" http://localhost:80 proxy 1
  [ $status -ne 0 ]
}
