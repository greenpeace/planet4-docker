#!/usr/bin/env bash
set -a

. ${BATS_TEST_DIRNAME}/../../../../env
. ${BATS_TEST_DIRNAME}/../../../../helpers

# bats test parameters
compose_file=${BATS_TEST_DIRNAME}/../docker-compose.yml
image="${IMAGE_NAMESPACE}/${BATS_PROJECT_ID}/${BATS_IMAGE}:${IMAGE_TAG}"
container_name="testing_${BATS_PROJECT_ID}_${BATS_IMAGE}"

# docker-compose.yml environment variables
APP_HOSTNAME=testing.local
PHP_MEMORY_LIMIT=192M
UPLOAD_MAX_SIZE=42M
