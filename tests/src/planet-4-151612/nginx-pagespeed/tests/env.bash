#!/usr/bin/env bash
set -a

# shellcheck source=./../../../../env
. ${BATS_TEST_DIRNAME}/../../../../env
# shellcheck source=./../../../../helpers
. ${BATS_TEST_DIRNAME}/../../../../helpers

compose_file=${BATS_TEST_DIRNAME}/../docker-compose.yml
container_name="testing_${BATS_PROJECT_ID}_${BATS_IMAGE}"
image="${IMAGE_NAMESPACE}/${BATS_PROJECT_ID}/${BATS_IMAGE}:${IMAGE_TAG}"
export compose_file
export container_name
export image

ENDPOINT_PORT=8080
ENDPOINT="http://localhost:${ENDPOINT_PORT}"
export ENDPOINT_PORT
export ENDPOINT
