#!/usr/bin/env bats
set -e

load env

envsubst < "${BATS_DIRECTORY:-${BATS_TEST_DIRNAME}/..}/Dockerfile.in" > "${BATS_DIRECTORY:-${BATS_TEST_DIRNAME}/..}/Dockerfile"

function setup {
  begin_output
}

function teardown {
  store_output
}

@test "wp-cli has database connection" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.yml" exec php-fpm wp db check
  [[ $status -eq 0 ]]
}

@test "wp-cli gets wordpress version" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.yml" exec php-fpm wp core version
  [ $status -eq 0 ]
  version_detect="[[:digit:]]+\\.[[:digit:]]+"
  printf '%s' "$output" | grep -Eq "$version_detect"
}

@test "wp-cli get blogname == ${WP_TITLE}" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.yml" exec php-fpm wp option get blogname
  [[ $status -eq 0 ]]
  [[ $output =~ "${WP_TITLE}" ]]
}

@test "wp-cli can modify content" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.yml" exec php-fpm wp option set blogname "${RANDOM_TITLE}"
  [[ $status -eq 0 ]]
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.yml" exec php-fpm wp option get blogname
  [[ $status -eq 0 ]]
  [[ $output =~ "${RANDOM_TITLE}" ]]
}
