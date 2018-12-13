#!/usr/bin/env bats
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "image exists ${IMAGE_NAMESPACE}/${BATS_PROJECT_ID}/${BATS_IMAGE}:${IMAGE_TAG}" {
  run run_test_image_exists "${IMAGE_NAMESPACE}/${BATS_PROJECT_ID}/${BATS_IMAGE}.*${IMAGE_TAG}"
  [[ $status -eq 0 ]]
}

@test "service starts with minimal config" {
  run test_minimal_startup
  [[ $status -eq 0 ]]
}

@test "print service environment" {
  run print_docker_env "${image}"
  [[ $status -eq 0 ]]
}

@test "service responds 'ok' to health checks" {
  run test_fastcgi_response
  [[ $status -eq 0 ]]
  [[ $output =~ "ok" ]]
}

@test "service responds with PHP Version ${PHP_MAJOR_VERSION}" {
  run test_fastcgi_response "/app/source/public/index.php"
  [[ $status -eq 0 ]]
  [[ $output =~ "PHP Version ${PHP_MAJOR_VERSION}" ]]
  echo "$output" > "${ARTIFACT_LOGS_DIR}/${BATS_IMAGE}.index.php"
}

@test "service errors 404 on non-existent file" {
  run test_fastcgi_response "/app/source/public/error.php"
  [[ $output =~ "Status: 404 Not Found" ]]
  echo "$output" > "${ARTIFACT_LOGS_DIR}/${BATS_IMAGE}.error.php"
}

@test "minimal service cleans up" {
  run test_minimal_cleanup
  [[ $status -eq 0 ]]
}
