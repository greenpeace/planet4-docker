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
  [[ -z "${GITHUB_OAUTH_TOKEN}" ]] && >&2 echo "ERROR: GITHUB_OAUTH_TOKEN not set" && exit 1
  docker-compose  -f ${compose_file} stop || true
  yes | docker-compose -f ${compose_file} rm || true
  run docker-compose -f ${compose_file} build app
  [[ "$status" -eq 0 ]]
}

@test "image exists" {
  run run_test_image_exists "p4sampleapplication_app"
  [[ "$status" -eq 0 ]]
}

@test "container starts" {
  # Wait up to 10 minutes for the build to complete!
  run start_docker_compose ${BATS_TEST_DIRNAME}/../docker-compose.yml http://localhost:80 600
  [[ "$status" -eq 0 ]]
}

@test "container responds on port 80 with status 200" {
  skip "Awaiting 'container starts' to be implemented properly"
  run run_test_http_response_code
  [[ "$status" -eq 0 ]]
}

@test "container cleans up" {
  skip "Awaiting 'container starts' to be implemented properly"
  run clean_docker_compose "${compose_file}"
  [[ "$status" -eq 0 ]]
}
