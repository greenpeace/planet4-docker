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

# docker-compose.yml environment variables
APP_HOSTNAME=testing.local
ENDPOINT_PORT_HTTP=80
ENDPOINT_PORT_HTTPS=443
ENDPOINT_HTTP="http://localhost:${ENDPOINT_PORT_HTTP}"
ENDPOINT_HTTPS="https://localhost:${ENDPOINT_PORT_HTTPS}"
if [[ ${CI} ]]
then
  NETWORK_MODE="host"
else
  NETWORK_MODE="bridge"
fi
PHP_MEMORY_LIMIT=192M
UPLOAD_MAX_SIZE=42M
export APP_HOSTNAME
export ENDPOINT_PORT_HTTP
export ENDPOINT_PORT_HTTPS
export ENDPOINT_HTTP
export ENDPOINT_HTTPS
export NETWORK_MODE
export PHP_MEMORY_LIMIT
export UPLOAD_MAX_SIZE
