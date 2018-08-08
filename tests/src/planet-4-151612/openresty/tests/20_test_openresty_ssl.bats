#!/usr/bin/env bats
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "SSL - container starts" {
  run start_docker_compose "${BATS_TEST_DIRNAME}/../docker-compose.ssl.yml"
  [[ $status -eq 0 ]]
}

@test "SSL - print app environment" {
  run print_docker_compose_env app
  [[ $status -eq 0 ]]
}

@test "SSL - container responds on port 80 with status 200" {
  run curl_check_status_code
  [[ $status -eq 0 ]]
}

@test "SSL - container responds on port 443 with status 200" {
  run curl_check_status_code 200 "https://localhost:443" openresty_app_1
  [[ $status -eq 0 ]]
}

@test "SSL - http response contains regex 'nginx version: openresty/${OPENRESTY_VERSION}'" {
  run curl_check_response_regex "nginx version: openresty/${OPENRESTY_VERSION}" "https://localhost:443"
  [[ $status -eq 0 ]]
}

@test "SSL - http response contains regex 'built with OpenSSL ${OPENSSL_VERSION}'" {
  run curl_check_response_regex "built with OpenSSL ${OPENSSL_VERSION}" "https://localhost:443"
  [[ $status -eq 0 ]]
}

@test "SSL - container cleans up" {
  run clean_docker_compose
  [[ $status -eq 0 ]]
}
