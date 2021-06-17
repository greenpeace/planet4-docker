#!/usr/bin/env bash
set -e

if [[ -d "/opt/elastic/apm-agent-php/etc/" ]]; then
  dockerize -template /app/templates/etc/php/fpm/conf.d/30-elastic-apm-custom.ini.tmpl:/opt/elastic/apm-agent-php/etc/elastic-apm-custom.ini
fi
