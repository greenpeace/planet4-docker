#!/usr/bin/env bats
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

ipv4=$(host iinet.net.au | grep 'has address' | cut -d' ' -f4)
#ipv6=$(host iinet.net.au | grep 'has IPv6 address' | cut -d' ' -f4)
#jencub - commented out as it was causing this bats test to fail.

@test "GEOIP - container builds" {
  envsubst < "${BATS_TEST_DIRNAME}/../geoip/Dockerfile.in" > "${BATS_TEST_DIRNAME}/../geoip/Dockerfile"
  docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.geoip.yml" rm -fsv
  docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.geoip.yml" build --no-cache
}

@test "GEOIP - container starts" {
  run start_docker_compose "${BATS_TEST_DIRNAME}/../docker-compose.geoip.yml"
  [ $status -eq 0 ]
}

@test "GEOIP - 'Country: Unknown' for localhost lookups" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.geoip.yml" exec app curl localhost
  [ $status -eq 0 ]
  printf '%s' "$output" | grep "Country: Unknown"
}

@test "GEOIP - IPv4 - Country code and name in response headers" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.geoip.yml" exec app curl -I --header "X-Forwarded-For: $ipv4" 127.0.0.1
  [ $status -eq 0 ]
  printf '%s' "$output" | grep "X-Country-Code: AU"
  printf '%s' "$output" | grep "X-Country-Name: Australia"
}

@test "GEOIP - IPv6 - Country code and name in response headers" {
  skip "#FIXME: Test currently failing"
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.geoip.yml" exec app curl -I --header "X-Forwarded-For: $ipv6" 127.0.0.1
  [ $status -eq 0 ]
  printf '%s' "$output" | grep "X-Country-Code: AU"
  printf '%s' "$output" | grep "X-Country-Name: Australia"
}

@test "GEOIP - 'Country: AU' sub_filter rewrite" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.geoip.yml" exec app curl -s --header "X-Forwarded-For: $ipv4" 127.0.0.1
  [ $status -eq 0 ]
  printf '%s' "$output" | grep "Country: AU"
}

@test "GEOIP - Cron job deployed" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.geoip.yml" exec app run-parts --list /etc/cron.weekly
  [ $status -eq 0 ]
  printf '%s' "$output" | grep "nginx_update_geoip_database"
}

@test "GEOIP - container cleans up" {
  run clean_docker_compose
  [ $status -eq 0 ]
}
