#!/usr/bin/env bats
set -e

load env

#
# @test "shutdown existing containers" {
#   docker-compose -f "${compose_file}" down -v
# }
#
# @test "pull new container versions" {
#   docker-compose -f "${compose_file}" pull --parallel
# }

@test "docker-compose start: $IMAGE_TAG" {
  # Wait up to 10 minutes for the build to complete!
  run start_docker_compose "${BATS_TEST_DIRNAME}/../docker-compose.yml" http://localhost:80 proxy 20
  [ $status -eq 0 ]
}

@test "print openresty environment" {
  run print_docker_compose_env app
  [ $status -eq 0 ]
}

@test "print php-fpm environment" {
  run print_docker_compose_env php-fpm
  [ $status -eq 0 ]
}

@test "responds on port 80 with status 200" {
  run curl_check_status_code 200 http://localhost:80 proxy 10
  [ $status -eq 0 ]
  [ $output -eq 200 ]
}

@test "response contains string 'greenpeace'" {
  run curl_check_response_regex "greenpeace" http://localhost:80 proxy 5
  [ $status -eq 0 ]
}

@test "response does not contain string 'FNORDPTANGWIBBLE'" {
  run curl_check_response_regex "FNORDPTANGWIBBLE" http://localhost:80 proxy 1
  [ $status -ne 0 ]
}
