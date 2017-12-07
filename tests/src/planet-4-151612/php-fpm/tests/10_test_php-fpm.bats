#!/usr/bin/env bats
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "pull image: ${image}" {
  run pull_image "${image}"
  [[ $status -eq 0 ]]
}

@test "image exists" {
  run run_test_image_exists "${IMAGE_NAMESPACE}/${BATS_PROJECT_ID}/${BATS_IMAGE}.*${IMAGE_TAG}"
  [[ $status -eq 0 ]]
}

@test "service starts with minimal config" {
  run test_minimal_startup
  [[ $status -eq 0 ]]
}

@test "service responds 'ok' to health checks" {
  run test_fastcgi_response
  [[ $status -eq 0 ]]
  [[ $output =~ "ok" ]]
}

@test "service responds with PHP Version ${PHP_MAJOR_VERSION}" {
  run test_fastcgi_response "/app/www/index.php"
  [[ $status -eq 0 ]]
  [[ $output =~ "PHP Version ${PHP_MAJOR_VERSION}" ]]
}

@test "service responds with newrelic.enabled yes" {
  run test_fastcgi_response "/app/www/index.php"
  [[ $status -eq 0 ]]
  [[ $output =~ newrelic.enabled.*yes ]]
}


@test "service responds with opcache.enable On" {
  run test_fastcgi_response "/app/www/index.php"
  [[ $status -eq 0 ]]
  [[ $output =~ opcache.enable.*On ]]
}

@test "minimal service cleans up" {
  run test_minimal_cleanup
  [[ $status -eq 0 ]]
}

@test "docker-compose nginx/php-fpm application starts" {
  run start_docker_compose
  [[ $status -eq 0 ]]
}

@test "docker-compose nginx/php-fpm application responds on port 80 with status 200" {
  run curl_check_status_code
  [[ $status -eq 0 ]]
}

@test "docker-compose nginx/php-fpm application fails to respond on port 443" {
  run curl_check_status_code 200 ${ENDPOINT_HTTPS}
  [[ $status -ne 0 ]]
}

@test "docker-compose nginx/php-fpm application response contains PHP 7 version string" {
  run curl_check_response_regex "PHP Version 7.[0-9]*.[0-9]*" "http://localhost/index.php" phpfpm_nginx_1
  [[ $status -eq 0 ]]
}

@test "docker-compose nginx/php-fpm application environment variable set correctly: PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT}" {
  run curl_check_response_regex "memory_limit.*${PHP_MEMORY_LIMIT}" "http://localhost/index.php" phpfpm_nginx_1
  [[ $status -eq 0 ]]
}

@test "docker-compose nginx/php-fpm application environment variable set correctly: UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE}" {
  run curl_check_response_regex "upload_max_filesize.*${UPLOAD_MAX_SIZE}" "http://localhost/index.php" phpfpm_nginx_1
  [[ $status -eq 0 ]]
  run curl_check_response_regex "post_max_size.*${UPLOAD_MAX_SIZE}" "http://localhost/index.php" phpfpm_nginx_1
  [[ $status -eq 0 ]]
}

@test "docker-compose nginx/php-fpm application container cleans up" {
  run clean_docker_compose
  [[ $status -eq 0 ]]
}
