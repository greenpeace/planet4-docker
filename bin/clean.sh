#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------------

# Find real file path of current script
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within

source="${BASH_SOURCE[0]}"
while [[ -h "$source" ]]
do # resolve $source until the file is no longer a symlink
  dir="$( cd -P "$( dirname "$source" )" && pwd )"
  source="$(readlink "$source")"
  [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
GIT_ROOT_DIR="$( cd -P "$( dirname "$source" )/.." && pwd )"

find "${GIT_ROOT_DIR}/src" -name "Dockerfile" -exec rm -r "{}" \;
find "${GIT_ROOT_DIR}/tests/src" -name "Dockerfile" -exec rm -r "{}" \;

test_containers=(
  "p4sampleapplication_openresty" \
  "p4sampleapplication_php-fpm" \
  "p4sampleapplication_db" \
  "phpfpm_nginx" \
  "phpfpm_php-fpm" \
  "openresty_app" \
)

for container in "${test_containers[@]}"
do
  # FIXME get actual container numbers properly
  # stop running container
  docker stop ${container}_1 >/dev/null 2>&1 &
  docker stop ${container}_2 >/dev/null 2>&1 &
  docker stop ${container}_3 >/dev/null 2>&1 &
  docker stop ${container}_4 >/dev/null 2>&1 &
  wait
  docker rm ${container}_1 >/dev/null 2>&1 &
  docker rm ${container}_2 >/dev/null 2>&1 &
  docker rm ${container}_3 >/dev/null 2>&1 &
  docker rm ${container}_4 >/dev/null 2>&1 &
  wait
  docker rmi -f ${container} >/dev/null 2>&1
done
docker network rm p4sampleapplication_default >/dev/null 2>&1 || true
docker volume rm -f p4sampleapplication_data >/dev/null 2>&1 || true
