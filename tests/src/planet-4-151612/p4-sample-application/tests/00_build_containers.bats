#!/usr/bin/env bats
set -e

load env

# Build Dockerfile variables from template file
# ENVVARS=(
#   '${APP_HOSTNAME}' \
#   '${BATS_PROJECT_ID}' \
#   '${IMAGE_NAMESPACE}' \
#   '${COMPOSER}' \
#   '${IMAGE_TAG}' \
#   '${WP_TITLE}' \
# )

# ENVVARS_STRING="$(printf "%s:" "${ENVVARS[@]}")"
# ENVVARS_STRING="${ENVVARS_STRING%:}"

envsubst < "${BATS_DIRECTORY:-${BATS_TEST_DIRNAME}/..}/Dockerfile.in" > "${BATS_DIRECTORY:-${BATS_TEST_DIRNAME}/..}/Dockerfile"

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "php-application builds successfully" {
  # [[ -z "${GITHUB_OAUTH_TOKEN}" ]] && >&2 echo "ERROR: GITHUB_OAUTH_TOKEN not set" && exit 1
  gcloud container builds submit "${BATS_TEST_DIRNAME}/.." --tag gcr.io/planet-4-151612/p4-sample-application_php-fpm
  # docker-compose -f "${compose_file}" build --no-cache php-fpm
}

@test "remove stale builds" {
  docker rmi p4-sample-application_php-fpm -f || true
}

@test "pull new build" {
  docker pull gcr.io/planet-4-151612/p4-sample-application_php-fpm
}

@test "image exists" {
  run run_test_image_exists "p4-sample-application_php-fpm"
  [[ $status -eq 0 ]]
}

@test "image is recent" {
  run run_test_image_exists "p4-sample-application_php-fpm"
  [[ $status -eq 0 ]]
  [[ $output =~ "second" ]]
}
