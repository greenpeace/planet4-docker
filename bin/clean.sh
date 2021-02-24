#!/usr/bin/env bash
set -euo pipefail
# ----------------------------------------------------------------------------

# Find real file path of current script
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
source="${BASH_SOURCE[0]}"
while [[ -L "$source" ]]; do # resolve $source until the file is no longer a symlink
  dir="$(cd -P "$(dirname "$source")" && pwd)"
  source="$(readlink "$source")"
  [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
GIT_ROOT_DIR="$(cd -P "$(dirname "$source")/.." && pwd)"

# Remove dockerfiles
find "${GIT_ROOT_DIR}/src" -name "Dockerfile" -exec rm -r "{}" \;
find "${GIT_ROOT_DIR}/tests/src" -name "Dockerfile" -exec rm -r "{}" \;

# Remove test containers
docker-compose -f "${GIT_ROOT_DIR}/tests/src/planet-4-151612/php-fpm/docker-compose.yml" stop || true
docker-compose -f "${GIT_ROOT_DIR}/tests/src/planet-4-151612/php-fpm/docker-compose.yml" down -v --remove-orphans || true
docker-compose -f "${GIT_ROOT_DIR}/tests/src/planet-4-151612/wordpress/docker-compose.yml" stop || true
docker-compose -f "${GIT_ROOT_DIR}/tests/src/planet-4-151612/wordpress/docker-compose.yml" down -v --remove-orphans || true

test_containers=(
  "p4sampleapplication_openresty"
  "openresty_app"
  "p4sampleapplication_db"
  "p4sampleapplication_redis"
  "p4sampleapplication_php-fpm"
  "php-fpm_nginx"
  "php-fpm_php-fpm"
  "php-fpm-test"
  "phpfpm-test"
  "exim_mail"
)

for i in $(docker ps --format '{{.Names}}'); do
  for j in "${test_containers[@]}"; do
    [[ $i =~ $j ]] || continue
    echo " . $i ... "
    docker rm -f "${i}" >/dev/null 2>&1 &
  done
  wait

done
