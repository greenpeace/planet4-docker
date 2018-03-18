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

envsubst "${ENVVARS_STRING}" < "${BATS_DIRECTORY:-${BATS_TEST_DIRNAME}/..}/Dockerfile.in" > "${BATS_DIRECTORY:-${BATS_TEST_DIRNAME}/..}/Dockerfile"

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "php-application builds successfully: $image" {
  [[ -z "${GITHUB_OAUTH_TOKEN}" ]] && >&2 echo "ERROR: GITHUB_OAUTH_TOKEN not set" && exit 1
  docker-compose -f "${compose_file}" down -v
  docker-compose -f "${compose_file}" pull
  run docker-compose -f "${compose_file}" build php-fpm
  [[ $status -eq 0 ]]
}

@test "image exists" {
  run run_test_image_exists "p4sampleapplication_php-fpm"
  [[ $status -eq 0 ]]
}

@test "image is recent" {
  run run_test_image_exists "p4sampleapplication_php-fpm"
  [[ $status -eq 0 ]]
  [[ $output =~ "second" ]]
}

@test "container starts" {
  # Wait up to 10 minutes for the build to complete!
  run start_docker_compose "${BATS_TEST_DIRNAME}/../docker-compose.yml" http://localhost:80 p4sampleapplication_openresty_1 600
  [[ "$status" -eq 0 ]]
}

@test "print openresty environment" {
  run print_docker_compose_env openresty
  [[ $status -eq 0 ]]
}

@test "print php-fpm environment" {
  run print_docker_compose_env php-fpm
  [[ $status -eq 0 ]]
}

@test "container responds on port 80 with status 200" {
  run curl_check_status_code 200 http://localhost:80 p4sampleapplication_openresty_1
  [[ $status -eq 0 ]]
  [[ $output -eq "200" ]]
}

@test "container response contains string 'greenpeace'" {
  run curl_check_response_regex "greenpeace" http://localhost:80 p4sampleapplication_openresty_1
  [[ $status -eq 0 ]]
}

@test "container response does not contain string 'FNORDPTANGWIBBLE'" {
  run curl_check_response_regex "FNORDPTANGWIBBLE" http://localhost:80 p4sampleapplication_openresty_1 1
  [[ $status -ne 0 ]]
}

@test "wp-cli has database connection" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.yml" exec php-fpm wp db check
  [[ $status -eq 0 ]]
}

@test "wp-cli can modify content" {
  skip "todo"
}

@test "container restarts with modified content" {
  skip "todo"
}

@test "can overwrite existing files" {
  skip "todo"
}

@test "container cleans up" {
  run clean_docker_compose "${compose_file}"
  [[ "$status" -eq 0 ]]
}
