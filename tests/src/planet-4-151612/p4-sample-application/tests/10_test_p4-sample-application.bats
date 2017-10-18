#!/usr/bin/env bats
set -e

load env

# Build Dockerfile variables from template file
ENVVARS=(
  '${APP_HOSTNAME}' \
  '${BATS_PROJECT_ID}' \
  '${IMAGE_NAMESPACE}' \
  '${COMPOSER}' \
  '${IMAGE_TAG}' \
)

ENVVARS_STRING="$(printf "%s:" "${ENVVARS[@]}")"
ENVVARS_STRING="${ENVVARS_STRING%:}"

envsubst "${ENVVARS_STRING}" < ${BATS_DIRECTORY:-"${BATS_TEST_DIRNAME}/.."}/Dockerfile.in > ${BATS_DIRECTORY:-"${BATS_TEST_DIRNAME}/.."}/Dockerfile

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "application builds successfully: ${image}" {
  run docker-compose -f ${compose_file} build app
  [[ "$status" -eq 0 ]]
}

@test "image exists" {
  run run_test_image_exists "${IMAGE_NAMESPACE}/${BATS_PROJECT_ID}/${BATS_IMAGE}.*${IMAGE_TAG}"
  [[ "$status" -eq 0 ]]
}

@test "container starts" {
  run start_docker_compose
  [[ "$status" -eq 0 ]]
}

@test "container responds on port 80 with status 200" {
  run run_test_http_response_code
  [[ "$status" -eq 0 ]]
}

@test "container cleans up" {
  run clean_docker_compose "${compose_file}"
  [[ "$status" -eq 0 ]]
}
