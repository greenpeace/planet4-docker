#!/usr/bin/env bats
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

EXT_IP=$(curl -s http://ipecho.net/plain; echo)

@test "CloudFlare - container starts" {
  run start_docker_compose "${BATS_TEST_DIRNAME}/../docker-compose.cloudflare.yml"
  [ $status -eq 0 ]
}

@test "Cloudflare - CF Real IP enabled" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.cloudflare.yml" exec app nginx -T
  [ $status -eq 0 ]
  printf '%s' "$output" | grep "CF-Connecting-IP"
}

@test "Cloudflare - Country Code enabled" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.cloudflare.yml" exec app nginx -T
  [ $status -eq 0 ]
  printf '%s' "$output" | grep "CF-IPCountry"
}

@test "Cloudflare - Configuration deployed" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.cloudflare.yml" exec app nginx -T
  [ $status -eq 0 ]
  printf '%s' "$output" | grep "/etc/nginx/conf.d/cloudflare-ips.conf"
}

@test "Cloudflare - IP matches CloudFlare IP" {
  skip "#FIXME: Test currently failing"
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.cloudflare.yml" exec app curl -v --header "CF-Connecting-IP: $EXT_IP" 127.0.0.1
  [ $status -eq 0 ]
  printf '%s' "$output" | grep $EXT_IP
}

@test "Cloudflare - Cron job deployed" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.cloudflare.yml" exec app run-parts --list /etc/cron.daily
  [ $status -eq 0 ]
  printf '%s' "$output" | grep "nginx_update_cloudflare_ips"
}

@test "CloudFlare - container cleans up" {
  run clean_docker_compose
  [ $status -eq 0 ]
}
