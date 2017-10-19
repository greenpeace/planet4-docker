#!/usr/bin/env bats
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "pull image" {
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
  run run_test_http_response_code
  [[ $status -eq 0 ]]
}

@test "container fails to respond on port 443" {
  run run_test_http_response_code 200 https://localhost:443
  [[ $status -ne 0 ]]
}

@test "container cleans up" {
  run clean_docker_compose
  [[ $status -eq 0 ]]
}
