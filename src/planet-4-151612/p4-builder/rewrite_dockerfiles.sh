#!/usr/bin/env bash
set -eu

export SOURCE_PATH=/app/source

# Specify which Dockerfile|README.md variables we want to change
# shellcheck disable=SC2016
# envvars=(
#   '${INFRA_VERSION}' \
#   '${GIT_REF}' \
#   '${GIT_SOURCE}' \
#   '${GOOGLE_PROJECT_ID}' \
#   '${MAINTAINER}' \
#   '${SOURCE_PATH}' \
# )
# envvars_string="$(printf "%s:" "${envvars[@]}")"

for i in build app openresty
do
  build_dir=$i
  envsubst < "${build_dir}/Dockerfile.in" > "${build_dir}/Dockerfile"
done
