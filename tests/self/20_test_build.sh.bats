#!/usr/bin/env bash
set -e

load env

function setup {
  begin_output
}

function teardown {
  store_output
}
# ------------------------------------------------------------------------------
# APPLICATION_NAME
#
@test "${PROJECT_ID} :: build.sh : \$APPLICATION_NAME : */Dockerfile : 1 line" {
  application_name="$(grep "APPLICATION_NAME=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  shopt -s nullglob
  for i in "${PROJECT_GIT_ROOT_DIR}"/src/${PROJECT_ID}/*/
  do
    run simple_grep "$application_name" "${i}Dockerfile"
    [ $status -eq 0 ]
    # [[ $(wc -l <<<"$output") -eq 1 ]]
  done
  shopt -u nullglob
}

@test "${TEST_CONFIG_FILE/$PWD/.} exists" {
  [ -f "${TEST_CONFIG_FILE}" ]
}

@test "${PROJECT_GIT_ROOT_DIR/$PWD/.}/src/${PROJECT_ID}/ubuntu/Dockerfile exists" {
  [ -f "${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/ubuntu/Dockerfile" ]
}

# ------------------------------------------------------------------------------
# BASEIMAGE_VERSION
#
@test "${PROJECT_ID} :: build.sh : \$BASEIMAGE_VERSION : ubuntu/Dockerfile : 1 line" {
  baseimage_version="$(grep "BASEIMAGE_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run simple_grep "FROM phusion/baseimage:${baseimage_version}" "${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/ubuntu/Dockerfile"
  [ ${status} -eq 0 ]
  # [[ $(wc -l <<<"$output") -eq 1 ]]
}

# ------------------------------------------------------------------------------
# CONTAINER_TIMEZONE
#
@test "${PROJECT_ID} :: build.sh : \$CONTAINER_TIMEZONE : ubuntu/Dockerfile : 1 line" {
  container_timezone="$(grep "CONTAINER_TIMEZONE=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run simple_grep "CONTAINER_TIMEZONE=\"${container_timezone}\"" "${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/ubuntu/Dockerfile"
  [ ${status} -eq 0 ]
  # [[ $(wc -l <<<"$output") -eq 1 ]]
}

# ------------------------------------------------------------------------------
# DOCKERIZE_VERSION
#
@test "${PROJECT_ID} :: build.sh : \$DOCKERIZE_VERSION : ubuntu/Dockerfile : 3 lines" {
  [ -f "${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/ubuntu/Dockerfile" ]
  dockerize_version="$(grep "DOCKERIZE_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run simple_grep "dockerize-linux-amd64-v${dockerize_version}" "${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/ubuntu/Dockerfile"
  [ ${status} -eq 0 ]
  # [[ $(wc -l <<<"$output") -eq 3 ]]
}

# ------------------------------------------------------------------------------
# OPENRESTY_VERSION
#
@test "${PROJECT_ID} :: build.sh : \$OPENRESTY_VERSION : openresty/Dockerfile" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/openresty/Dockerfile"
  nginx_version="$(grep "OPENRESTY_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  grep "OPENRESTY_VERSION=\"${nginx_version}\"" "${srcfile}"
}
