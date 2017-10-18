#!/usr/bin/env bats
set -e

load env

@test "pull image: ${image}" {
  pull_image "${image}"
}

@test "image exists" {
  run run_test_image_exists "${IMAGE_NAMESPACE}/${BATS_PROJECT_ID}/${BATS_IMAGE}.*${IMAGE_TAG}"
  [ "$status" -eq 0 ]
}

@test "container starts successfully" {
  start_docker_compose
}

@test "container responds on port 80 with status 200" {
  run run_test_http_response_code 200
  [ "$status" -eq 0 ]
}

@test "container responds on port 443 with status 200" {
  run run_test_http_response_code 200 "https://localhost:443"
  [ "$status" -eq 0 ]
}

@test "http response contains PHP 7 version string" {
  run_test_http_response_grep "PHP Version 7.[0-9]*.[0-9]*"
}

@test "environment variable PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT}" {
  run_test_http_response_grep "memory_limit.*${PHP_MEMORY_LIMIT}"
}

@test "environment variable UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE}" {
  run_test_http_response_grep "upload_max_filesize.*${UPLOAD_MAX_SIZE}"
  run_test_http_response_grep "post_max_size.*${UPLOAD_MAX_SIZE}"
}

# @test "container cleans up" {
#   run clean_docker_compose "${compose_file}"
#   [ "$status" -eq 0 ]
# }
