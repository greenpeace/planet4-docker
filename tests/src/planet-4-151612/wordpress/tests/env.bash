#!/usr/bin/env bash
set -a

. "${BATS_TEST_DIRNAME}/../../../../../bin/inc/main"
. "${BATS_TEST_DIRNAME}/../../../../_env"
. "${BATS_TEST_DIRNAME}/../../../../_helpers"

# bats test parameters
compose_file="${BATS_TEST_DIRNAME}/../docker-compose.yml"
container_name="testing_${BATS_PROJECT_ID}_${BATS_IMAGE}"
image="${IMAGE_NAMESPACE}/${BATS_PROJECT_ID}/${BATS_IMAGE}:${IMAGE_TAG}"

export compose_file
export container_name
export image

# docker-compose.yml environment variables
APP_HOSTNAME="test.planet4.dev"
DB_IMAGE="mysql:5.7"
GIT_SOURCE="https://github.com/greenpeace/planet4-base-fork"
GIT_BRANCH="develop"
RANDOM_TITLE="Test-mcBkUCqAO3yCvAjy"
WP_TITLE="Greenpeace - Testing"
export APP_HOSTNAME
export DB_IMAGE
export GIT_SOURCE
export GIT_BRANCH
export RANDOM_TITLE
export WP_TITLE
