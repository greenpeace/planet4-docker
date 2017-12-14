#!/usr/bin/env bash
set -e

if [[ ${NEWRELIC_ENABLED} = 'true' ]]
then
  if [[ -z "${NEWRELIC_LICENSE}" ]]
  then
    NEWRELIC_ENABLED="false"
    export NEWRELIC_ENABLED
    _warning "$(printf "%-10s " "php:")" "NEWRELIC_LICENSE is blank, license key is required"
    _warning "$(printf "%-10s " "php:")" "disabling newrelic"
  else
    _good "$(printf "%-10s " "php:")" "$(printf "%-22s" "newrelic.enabled:")" "${NEWRELIC_ENABLED}"
    _good "$(printf "%-10s " "php:")" "$(printf "%-22s" "newrelic.appname:")" "${NEWRELIC_APPNAME}"
    _good "$(printf "%-10s " "php:")" "$(printf "%-22s" "newrelic.license:")" "${NEWRELIC_LICENSE}"
  fi
fi

dockerize -template /app/templates/etc/php/fpm/conf.d/20-newrelic.ini.tmpl:/etc/php/${PHP_MAJOR_VERSION}/fpm/conf.d/20-newrelic.ini
