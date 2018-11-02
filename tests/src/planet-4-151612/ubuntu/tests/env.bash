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
