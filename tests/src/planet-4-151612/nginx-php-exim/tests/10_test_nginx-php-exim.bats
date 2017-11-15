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
  skip "Development on this container halted"
  run pull_image "${image}"
  [[ $status -eq 0 ]]
}

@test "image exists" {
  skip "Development on this container halted"
  run run_test_image_exists "${IMAGE_NAMESPACE}/${BATS_PROJECT_ID}/${BATS_IMAGE}.*${IMAGE_TAG}"
  [[ $status -eq 0 ]]
}

@test "container starts" {
  skip "Development on this container halted"
  run start_docker_compose
  [[ $status -eq 0 ]]
}

@test "container responds on port 80 with status 200" {
  skip "Development on this container halted"
  run curl_check_status_code
  [[ $status -eq 0 ]]
}

@test "container responds on port 443 with status 200" {
  skip "Development on this container halted"
  run curl_check_status_code 200 ${ENDPOINT_HTTPS}
  [[ $status -eq 0 ]]
}

@test "http response contains PHP 7 version string" {
  skip "Development on this container halted"
  run curl_check_response_regex "PHP Version 7.[0-9]*.[0-9]*"
  [[ $status -eq 0 ]]
}

@test "environment variable set correctly: PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT}" {
  skip "Development on this container halted"
  run curl_check_response_regex "memory_limit.*${PHP_MEMORY_LIMIT}"
  [[ $status -eq 0 ]]
}

@test "environment variable set correctly: UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE}" {
  skip "Development on this container halted"
  run curl_check_response_regex "upload_max_filesize.*${UPLOAD_MAX_SIZE}"
  [[ $status -eq 0 ]]
  run curl_check_response_regex "post_max_size.*${UPLOAD_MAX_SIZE}"
  [[ $status -eq 0 ]]
}

@test "container cleans up" {
  skip "Development on this container halted"
  run clean_docker_compose
  [[ $status -eq 0 ]]
}
