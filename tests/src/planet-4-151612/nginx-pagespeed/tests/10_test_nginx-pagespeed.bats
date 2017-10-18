#!/usr/bin/env bats
set -e

load env

@test "pull image: ${image}" {
  pull_image "${image}"
}

@test "image exists" {
  run_test_image_exists "${IMAGE_NAMESPACE}/${BATS_PROJECT_ID}/${BATS_IMAGE}.*${IMAGE_TAG}"
}

@test "container starts" {
  # run run_test_container_starts "${image}"
  run start_docker_compose
  [ "$status" -eq 0 ]
}

@test "container responds on port 80 with status 200" {
  run run_test_http_response_code 200
  [ "$status" -eq 0 ]
}

@test "container errors on port 443" {
  run run_test_http_response_code 200 https://localhost:443
  [ "$status" -eq 1 ]
}

@test "container cleans up" {
  run clean_docker_compose "${compose_file}"
  [ "$status" -eq 0 ]
}
