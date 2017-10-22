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
  run run_test_image_exists "${IMAGE_NAMESPACE}/${BATS_PROJECT_ID}/${BATS_IMAGE}.*${IMAGE_TAG}"
  [[ $status -eq 0 ]]
}

@test "container starts" {
  run start_docker_compose
  [[ $status -eq 0 ]]
}

@test "container responds on port 80 with status 200" {
  run curl_check_status_code
  [[ $status -eq 0 ]]
}

@test "container responds on port 443 with status 200" {
  run curl_check_status_code ${ENDPOINT_HTTPS}
  [[ $status -eq 0 ]]
}

@test "http response contains PHP 7 version string" {
  run curl_check_response_regex ${ENDPOINT_HTTPS} $(get_container_name) "PHP Version 7.[0-9]*.[0-9]*"
  [[ $status -eq 0 ]]
}

@test "environment variable set correctly: PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT}" {
  run curl_check_response_regex ${ENDPOINT_HTTP} $(get_container_name) "memory_limit.*${PHP_MEMORY_LIMIT}"
  [[ $status -eq 0 ]]
}

@test "environment variable set correctly: UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE}" {
  run curl_check_response_regex ${ENDPOINT_HTTP} $(get_container_name) "upload_max_filesize.*${UPLOAD_MAX_SIZE}"
  [[ $status -eq 0 ]]
  run curl_check_response_regex ${ENDPOINT_HTTP} $(get_container_name) "post_max_size.*${UPLOAD_MAX_SIZE}"
  [[ $status -eq 0 ]]
}

@test "container cleans up" {
  run clean_docker_compose
  [[ $status -eq 0 ]]
}
