#!/usr/bin/env bash
set -e

load env

function setup {
  begin_output
  # Perform the build once only
  if [[ $BATS_TEST_NUMBER -eq 1 ]]
  then
    "${PROJECT_GIT_ROOT_DIR}/bin/build.sh" -c "${TEST_CONFIG_FILE}"
  fi
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
  for i in ${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/*/
  do
    run grep "$application_name" "${i}Dockerfile"
    [[ $status -eq 0 ]]
    [[ $(wc -l <<<"$output") -eq 1 ]]
  done
  shopt -u nullglob
}
# ------------------------------------------------------------------------------
# BASEIMAGE_VERSION
#
@test "${PROJECT_ID} :: build.sh : \$BASEIMAGE_VERSION : ubuntu/Dockerfile : 1 line" {
  baseimage_version="$(grep "BASEIMAGE_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run grep "FROM phusion/baseimage:${baseimage_version}" "${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/ubuntu/Dockerfile"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 1 ]]
}
# ------------------------------------------------------------------------------
# CONTAINER_TIMEZONE
#
@test "${PROJECT_ID} :: build.sh : \$CONTAINER_TIMEZONE : ubuntu/Dockerfile : 1 line" {
  container_timezone="$(grep "CONTAINER_TIMEZONE=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run grep "DEFAULT_CONTAINER_TIMEZONE=\"${container_timezone}\"" "${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/ubuntu/Dockerfile"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 1 ]]
}

# ------------------------------------------------------------------------------
# DOCKERIZE_VERSION
#
@test "${PROJECT_ID} :: build.sh : \$DOCKERIZE_VERSION : ubuntu/Dockerfile : 3 lines" {
  dockerize_version="$(grep "DOCKERIZE_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run grep "dockerize-linux-amd64-v${dockerize_version}" "${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/ubuntu/Dockerfile"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 3 ]]
}

# ------------------------------------------------------------------------------
# NGX_PAGESPEED_RELEASE
#
@test "${PROJECT_ID} :: build.sh : \$NGX_PAGESPEED_RELEASE : openresty/Dockerfile : 5 lines" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/openresty/Dockerfile"
  ngx_pagespeed_release="$(grep "NGX_PAGESPEED_RELEASE=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  grep "NGX_PAGESPEED_RELEASE=\"${ngx_pagespeed_release}\"" "${srcfile}"
  run grep "${ngx_pagespeed_release}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 5 ]]
}

@test "${PROJECT_ID} :: build.sh : \$NGX_PAGESPEED_RELEASE : openresty/README.md : 1 lines" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/openresty/README.md"
  ngx_pagespeed_release="$(grep "NGX_PAGESPEED_RELEASE=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run grep "${ngx_pagespeed_release}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 1 ]]
}

@test "${PROJECT_ID} :: build.sh : \$NGX_PAGESPEED_RELEASE : php-fpm/README.md : 1 lines" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/php-fpm/README.md"
  ngx_pagespeed_release="$(grep "NGX_PAGESPEED_RELEASE=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run grep "${ngx_pagespeed_release}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 1 ]]
}

@test "${PROJECT_ID} :: build.sh : \$NGX_PAGESPEED_RELEASE : wordpress/README.md : 1 lines" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/wordpress/README.md"
  ngx_pagespeed_release="$(grep "NGX_PAGESPEED_RELEASE=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run grep "${ngx_pagespeed_release}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 1 ]]
}

# ------------------------------------------------------------------------------
# NGX_PAGESPEED_VERSION
#
@test "${PROJECT_ID} :: build.sh : \$NGX_PAGESPEED_VERSION : openresty/Dockerfile : 5 lines" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/openresty/Dockerfile"
  ngx_pagespeed_version="$(grep "NGX_PAGESPEED_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  grep "NGX_PAGESPEED_VERSION=\"${ngx_pagespeed_version}\"" "${srcfile}"
  run grep "${ngx_pagespeed_version}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 5 ]]
}

@test "${PROJECT_ID} :: build.sh : \$NGX_PAGESPEED_VERSION : openresty/README.md : 1 lines" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/openresty/README.md"
  ngx_pagespeed_version="$(grep "NGX_PAGESPEED_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run grep "${ngx_pagespeed_version}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 1 ]]
}

@test "${PROJECT_ID} :: build.sh : \$NGX_PAGESPEED_VERSION : php-fpm/README.md : 1 lines" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/php-fpm/README.md"
  ngx_pagespeed_version="$(grep "NGX_PAGESPEED_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run grep "${ngx_pagespeed_version}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 1 ]]
}

@test "${PROJECT_ID} :: build.sh : \$NGX_PAGESPEED_VERSION : wordpress/README.md : 1 lines" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/wordpress/README.md"
  ngx_pagespeed_version="$(grep "NGX_PAGESPEED_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run grep "${ngx_pagespeed_version}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 1 ]]
}

# ------------------------------------------------------------------------------
# OPENRESTY_VERSION
#
@test "${PROJECT_ID} :: build.sh : \$OPENRESTY_VERSION : openresty/Dockerfile : 3 lines" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/openresty/Dockerfile"
  nginx_version="$(grep "OPENRESTY_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  grep "OPENRESTY_VERSION=\"${nginx_version}\"" "${srcfile}"
  run grep "${nginx_version}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 3 ]]
}

@test "${PROJECT_ID} :: build.sh : \$OPENRESTY_VERSION : openresty/README.md : 1 line" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/openresty/README.md"
  nginx_version="$(grep "OPENRESTY_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run grep "${nginx_version}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 1 ]]
}

@test "${PROJECT_ID} :: build.sh : \$OPENRESTY_VERSION : php-fpm/README.md : 1 line" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/php-fpm/README.md"
  nginx_version="$(grep "OPENRESTY_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run grep "${nginx_version}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 1 ]]
}

@test "${PROJECT_ID} :: build.sh : \$OPENRESTY_VERSION : wordpress/README.md : 1 line" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/wordpress/README.md"
  nginx_version="$(grep "OPENRESTY_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run grep "${nginx_version}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 1 ]]
}

# ------------------------------------------------------------------------------
# OPENSSL_VERSION
#
@test "${PROJECT_ID} :: build.sh : \$OPENSSL_VERSION : openresty/Dockerfile : 3 lines" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/openresty/Dockerfile"
  openssl_version="$(grep "OPENSSL_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  grep "OPENSSL_VERSION=\"${openssl_version}\"" "${srcfile}"
  run grep "${openssl_version}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 3 ]]
}

@test "${PROJECT_ID} :: build.sh : \$OPENSSL_VERSION : openresty/README.md : 2 lines" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/openresty/README.md"
  openssl_version="$(grep "OPENSSL_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run grep "${openssl_version}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 2 ]]
}

@test "${PROJECT_ID} :: build.sh : \$OPENSSL_VERSION : php-fpm/README.md : 1 line" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/php-fpm/README.md"
  openssl_version="$(grep "OPENSSL_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run grep "${openssl_version}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 1 ]]
}

@test "${PROJECT_ID} :: build.sh : \$OPENSSL_VERSION : wordpress/README.md : 1 line" {
  srcfile="${PROJECT_GIT_ROOT_DIR}/src/${PROJECT_ID}/wordpress/README.md"
  openssl_version="$(grep "OPENSSL_VERSION=.*" "${TEST_CONFIG_FILE}" | cut -d \" -f 2)"
  run grep "${openssl_version}" "${srcfile}"
  [[ ${status} -eq 0 ]]
  [[ $(wc -l <<<"$output") -eq 1 ]]
}
