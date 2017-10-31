#!/usr/bin/env bash
set -a

if [ -z "${GITHUB_OAUTH_TOKEN}" ]
then
  echo 'ERROR: $GITHUB_OAUTH_TOKEN environment variable not set'
  exit 1
fi

# shellcheck source=/dev/null
. ${BATS_TEST_DIRNAME}/../../../../_env
# shellcheck source=/dev/null
. ${BATS_TEST_DIRNAME}/../../../../_helpers

# bats test parameters
compose_file=${BATS_TEST_DIRNAME}/../docker-compose.yml
container_name="testing_${BATS_PROJECT_ID}_${BATS_IMAGE}"
image="${IMAGE_NAMESPACE}/${BATS_PROJECT_ID}/${BATS_IMAGE}:${IMAGE_TAG}"
export compose_file
export container_name
export image

# Dockerfile.in replacements
COMPOSER="composer-dev.json"
export COMPOSER
# docker-compose.yml environment variables
APP_HOSTNAME="test.planet4.local"
DB_IMAGE="mysql:5.7"
export APP_HOSTNAME
export DB_IMAGE
