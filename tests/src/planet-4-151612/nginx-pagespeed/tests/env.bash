#!/usr/bin/env bash
set -a

compose_file=${BATS_DIRECTORY}/docker-compose.yml
image="${IMAGE_NAMESPACE}/${BATS_PROJECT_ID}/${BATS_IMAGE}:${IMAGE_TAG}"
container_name="testing_${BATS_PROJECT_ID}_${BATS_IMAGE}"
