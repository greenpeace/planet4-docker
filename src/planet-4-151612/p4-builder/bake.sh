#!/usr/bin/env bash
set -eu

function usage() {
  echo "Usage: $(basename "$0")

Performs initial composer install in container and exports the
generated files for use elsewhere.

"
}

[[ -d source ]] && rsync --exclude '.git' -av source/ build/source
[[ -d merge ]] && rsync --exclude '.git' -av merge/ build/source

# ----------------------------------------------------------------------------

docker-compose -p build down -v --remove-orphans

# ----------------------------------------------------------------------------

# Build the container and start
echo "Building containers..."
docker-compose -p build build
echo ""

echo "Starting containers..."
docker-compose -p build up -d
echo ""

# 2 seconds * 150 == 5+ minutes
interval=2
loop=150

# Number of consecutive successes to qualify as 'up'
threshold=3
success=0

docker-compose -p build logs -f &

until [[ $success -ge $threshold ]]
do
  # Curl to container and expect status code 200
  set +e
  docker run --network "container:build_app_1" --rm appropriate/curl -s -k "http://localhost:80" | grep -q "greenpeace"

  if [[ $? -eq 0 ]]
  then
    success=$((success+1))
    echo "Success: $success/$threshold"
  else
    success=0
  fi
  set -e

  loop=$((loop-1))
  if [[ $loop -lt 1 ]]
  then
    >&2 echo "[ERROR] Timeout waiting for docker-compose to start"
    >&2 docker-compose -p build logs
    exit 1
  fi

  [[ $success -ge $threshold ]] || sleep $interval

done

docker-compose logs php-fpm
echo ""

echo "Copying built source directory..."
docker cp build_app_1:/app/source/public/ source
echo ""

echo "Bringing down containers..."
docker-compose -p build down -v &
echo ""

shopt -s nullglob
numfiles=(source/public/*)
numfiles=${#numfiles[@]}

echo "$numfiles files in source/public"

if [[ $numfiles -lt 3 ]]
then
  >&2 echo "ERROR not enough files for a success"
  ls source/public
  exit 1
fi

# FIXME volume: nocopy not working in the docker-compse.yml file
rm -f source/public/index.html

# Tagged releases are production, remove the robots.txt
# FIXME Find a better way to handle robots.txt
if [[ ! -z "${CIRCLE_TAG:-}" ]]
then
  rm -f source/public/robots.txt
fi

wait # for docker-compose down to finish

echo "Done"
