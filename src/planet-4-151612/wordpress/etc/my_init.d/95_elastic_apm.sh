#!/usr/bin/env bash
set -e

dockerize -template /app/templates/etc/php/fpm/conf.d/30-elastic-apm-custom.ini.tmpl:/opt/elastic/apm-agent-php/etc/elastic-apm-custom.ini
