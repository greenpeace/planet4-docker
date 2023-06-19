#!/usr/bin/env bats
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

# @test "image exists" {
#   run run_test_image_exists "${IMAGE_NAMESPACE}/${BATS_PROJECT_ID}/${BATS_IMAGE}.*${IMAGE_TAG}"
#   [[ $status -eq 0 ]]
# }

@test "container starts" {
  run start_docker_compose
  [ $status -eq 0 ]
}

@test "print app environment" {
  run print_docker_compose_env app
  [ $status -eq 0 ]
}

@test "GEOIP_ENABLED Disabled - 'Country: __P4_GEOIP_COUNTRY_CODE__' in test output" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.yml" exec app curl localhost
  [ $status -eq 0 ]
  printf '%s' "$output" | grep "Country: __P4_GEOIP_COUNTRY_CODE__"
}

@test "container responds on port 80 with status 200" {
  run curl_check_status_code
  [ $status -eq 0 ]
}

@test "container fails to respond on port 443" {
  run curl_check_status_code 200 "https://localhost:443" openresty_app_1 3
  [ $status -ne 0 ]
}

@test "http response contains regex 'nginx version: openresty/${OPENRESTY_VERSION}'" {
  run curl_check_response_regex "nginx version: openresty/${OPENRESTY_VERSION}"
  [ $status -eq 0 ]
}

@test "http response contains regex 'built with OpenSSL'" {
  run curl_check_response_regex "built with OpenSSL"
  [ $status -eq 0 ]
}

@test "container cleans up" {
  run clean_docker_compose
  [ $status -eq 0 ]
}
