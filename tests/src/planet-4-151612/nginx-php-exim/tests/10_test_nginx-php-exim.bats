#!/usr/bin/env bats
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "pull image: ${image}" {
  run pull_image "${image}"
  [[ $status -eq 0 ]]
}

@test "image exists" {
  run run_test_image_exists "p4sampleapplication_app"
  [[ $status -eq 0 ]]
}

@test "container starts successfully" {
  run start_docker_compose
  [[ $status -eq 0 ]]
}

@test "container responds on port 80 with status 200" {
  run run_test_http_response_code 200
  [[ $status -eq 0 ]]
}

@test "container responds on port 443 with status 200" {
  run run_test_http_response_code 200 "https://localhost:443"
  [[ $status -eq 0 ]]
}

@test "http response contains PHP 7 version string" {
  run run_test_http_response_grep "PHP Version 7.[0-9]*.[0-9]*"
  [[ $status -eq 0 ]]
}

@test "environment variable set correctly: PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT}" {
  run run_test_http_response_grep "memory_limit.*${PHP_MEMORY_LIMIT}"
  [[ $status -eq 0 ]]
}

@test "environment variable set correctly: UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE}" {
  run run_test_http_response_grep "upload_max_filesize.*${UPLOAD_MAX_SIZE}"
  [[ $status -eq 0 ]]
  run run_test_http_response_grep "post_max_size.*${UPLOAD_MAX_SIZE}"
  [[ $status -eq 0 ]]
}

@test "container cleans up" {
  run clean_docker_compose "${compose_file}"
  [[ $status -eq 0 ]]
}
