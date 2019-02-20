#!/usr/bin/env bats
set -e

load env

# envsubst < "${BATS_DIRECTORY:-${BATS_TEST_DIRNAME}/..}/Dockerfile.in" > "${BATS_DIRECTORY:-${BATS_TEST_DIRNAME}/..}/Dockerfile"

@test "handbook 90_chmod_langauge_files.sh exists and is executable" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.yml" exec php-fpm stat -c "%a %n" /etc/my_init.d/90_chmod_language_files.sh
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "755"
}

@test "handbook WP_DISALLOW_FILE_MODS is false" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.yml" exec php-fpm grep DISALLOW_FILE_MODS /app/source/public/wp-config.php
  [ $status -eq 0 ]
  printf '%s' "$output" | grep -Eq "false"
}

@test "handbook file permissions are set correctly" {
  run docker-compose -f "${BATS_TEST_DIRNAME}/../docker-compose.yml" exec php-fpm stat -c "%a %n" /app/source/public/wp-content/themes/planet4-master-theme/languages/
  [ $status -eq 0 ]
}
