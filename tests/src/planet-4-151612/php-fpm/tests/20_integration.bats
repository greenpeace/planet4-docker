#!/usr/bin/env bats
set -e

load env

@test "docker-compose nginx/php-fpm application starts" {
  run start_docker_compose "${BATS_TEST_DIRNAME}/../docker-compose.yml" ${ENDPOINT_HTTP} php-fpm-app
  [ $status -eq 0 ]
}

@test "docker-compose nginx/php-fpm application responds on port 80 with status 200" {
  run curl_check_status_code 200 ${ENDPOINT_HTTP} php-fpm-app
  [ $status -eq 0 ]
}

@test "docker-compose nginx/php-fpm application shows PHP status internally" {
  run curl_check_response_regex "pool.*example_com" "http://localhost/_php_status" php-fpm-app 3
  [ $status -eq 0 ]
}

@test "docker-compose nginx/php-fpm application hides PHP status externally" {
  [ -z "$CI" ] || skip "Not functional in CI"
  run curl -s localhost/_php_status
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -E "403 Forbidden"
}

@test "docker-compose nginx/php-fpm application fails to respond on port 443" {
  run curl_check_status_code 200 ${ENDPOINT_HTTPS} php-fpm-app 3
  [ $status -ne 0 ]
}

@test "docker-compose nginx/php-fpm application response contains PHP 7 version string" {
  run curl_check_response_regex "PHP Version 7.[0-9]*.[0-9]*" "http://localhost/index.php" php-fpm-app
  [ $status -eq 0 ]
}

@test "docker-compose nginx/php-fpm application environment variable set correctly: PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT}" {
  run curl_check_response_regex "memory_limit.*${PHP_MEMORY_LIMIT}" "http://localhost/index.php" php-fpm-app
  [ $status -eq 0 ]
}

@test "docker-compose nginx/php-fpm application environment variable set correctly: UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE}" {
  run curl_check_response_regex "upload_max_filesize.*${UPLOAD_MAX_SIZE}" "http://localhost/index.php" php-fpm-app
  [ $status -eq 0 ]
  run curl_check_response_regex "post_max_size.*${UPLOAD_MAX_SIZE}" "http://localhost/index.php" php-fpm-app
  [ $status -eq 0 ]
}
