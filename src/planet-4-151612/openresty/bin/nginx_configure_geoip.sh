#!/usr/bin/env bash
set -euo pipefail

if [[ ${GEOIP_ENABLED} = "true" ]]; then
  COUNTRY_CODE=CF-IPCountry

  export COUNTRY_CODE

  files=(
    /etc/nginx/conf.d/90_geoip.conf
    /etc/nginx/server.d/90_geoip.conf
  )

  _good "$(printf "%-10s " "openresty:")" "COUNTRY_CODE ${COUNTRY_CODE}"

  for f in "${files[@]}"; do
    dockerize -template "/app/templates$f.tmpl:$f"
  done
fi
