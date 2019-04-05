#!/usr/bin/env bats
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "APP_HOSTPATH - container starts" {
  run start_docker_compose "${BATS_TEST_DIRNAME}/../docker-compose.hostpath.yml"
  [ $status -eq 0 ]
}

@test "APP_HOSTPATH - print app environment" {
  run print_docker_compose_env app "${BATS_TEST_DIRNAME}/../docker-compose.hostpath.yml"
  [ $status -eq 0 ]
}

@test "APP_HOSTPATH - container responds on port 80 with status 200" {
  run curl_check_status_code
  [ $status -eq 0 ]
}
#
@test "APP_HOSTPATH - container responds at path / with status 200" {
  path="http://localhost:80/"
  run curl_check_status_code 200 $path
  [ $status -eq 0 ]
}
#
@test "APP_HOSTPATH - container responds at path /testing with status 200" {
  path="http://localhost/testing"
  run curl_check_status_code 200 $path
  [ $status -eq 0 ]
}

@test "APP_HOSTPATH - container responds at path /testing/index.html with status 200" {
  run curl_check_status_code 200 http://localhost:80/testing/index.html
  [ $status -eq 0 ]
}

@test "APP_HOSTPATH - container responds at path ?s=greenpeace with status 200" {
  run curl_check_status_code 200 http://localhost:80?s=greenpeace
  [ $status -eq 0 ]
}

@test "APP_HOSTPATH - container responds at path /?s=greenpeace with status 200" {
  run curl_check_status_code 200 http://localhost:80/?s=greenpeace
  [ $status -eq 0 ]
}

@test "APP_HOSTPATH - container responds at path /testing?s=greenpeace with status 200" {
  run curl_check_status_code 200 http://localhost:80/testing?s=greenpeace
  [ $status -eq 0 ]
}

@test "APP_HOSTPATH - container responds at path /testing/?s=greenpeace with status 200" {
  run curl_check_status_code 200 http://localhost:80/testing/?s=greenpeace
  [ $status -eq 0 ]
}

@test "APP_HOSTPATH - container responds at path /does_not_exist with status 404" {
  run curl_check_status_code 404 http://localhost:80/does_not_exist
  [ $status -eq 0 ]
}

@test "APP_HOSTPATH - http response contains regex 'nginx version: openresty/${OPENRESTY_VERSION}'" {
  run curl_check_response_regex "nginx version: openresty/${OPENRESTY_VERSION}" http://localhost:80/testing
  [ $status -eq 0 ]
}

@test "APP_HOSTPATH - http response contains regex 'built with OpenSSL'" {
  run curl_check_response_regex "built with OpenSSL" http://localhost:80/testing
  [ $status -eq 0 ]
}

@test "APP_HOSTPATH - container cleans up" {
  run clean_docker_compose "${BATS_TEST_DIRNAME}/../docker-compose.hostpath.yml"
  [ $status -eq 0 ]
}
