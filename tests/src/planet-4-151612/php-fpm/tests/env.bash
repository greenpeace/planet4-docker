#!/usr/bin/env bash
set -a

# shellcheck source=/dev/null
. "${BATS_TEST_DIRNAME}/../../../../../bin/inc/main"
# shellcheck source=/dev/null
. "${BATS_TEST_DIRNAME}/../../../../_env"
# shellcheck source=/dev/null
. "${BATS_TEST_DIRNAME}/../../../../_helpers"

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


function setup {
  begin_output
}

function teardown {
  store_output
}

function test_minimal_cleanup() {
  local name="${1:-phpfpm-test}"

  docker rm -f $name
}

function test_minimal_startup() {
  set -exo pipefail
  trap finish EXIT
  local name="${1:-phpfpm-test}"

  docker rm -f $name >/dev/null || true

  docker run --name $name -d --rm $image
}

# Queries a fastcgi endpoint and expects a response to match regular expression parameter
function test_fastcgi_response() {
  set -exo pipefail
  trap finish EXIT
  local path=${1:-"/health-check"}
  local endpoint=${2:-"127.0.0.1:9000"}
  local container=${3:-"phpfpm-test"}
  # local out

  docker run --network "container:${container}" \
    -e "SCRIPT_FILENAME=${path}" \
    -e "SCRIPT_NAME=${path}" \
    -t --rm gcr.io/greenpeace-global-it/cgi-fcgi -bind -connect "${endpoint}"
}

export -f test_minimal_cleanup
export -f test_minimal_startup
export -f test_fastcgi_response
