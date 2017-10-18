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
  start_docker_compose
}

@test "container responds on port 80 with status 200" {
  run_test_http_response_code
}

@test "container fails to respond on port 443" {
  run run_test_http_response_code 200 https://localhost:443
  [[ "$status" -eq 1 ]]
}

@test "container cleans up" {
  clean_docker_compose "${compose_file}"
}
