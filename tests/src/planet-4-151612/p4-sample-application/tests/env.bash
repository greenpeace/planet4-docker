#!/usr/bin/env bash
set -a

# shellcheck source=./../../../../env
. ${BATS_TEST_DIRNAME}/../../../../env
# shellcheck source=./../../../../helpers
. ${BATS_TEST_DIRNAME}/../../../../helpers

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
export APP_HOSTNAME
