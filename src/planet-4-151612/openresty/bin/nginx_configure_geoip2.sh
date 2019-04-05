#!/usr/bin/env bash
set -euo pipefail

_good "$(printf "%-10s " "openresty:")" "GEOIP2 ${GEOIP2_ENABLED}"

[[ ${GEOIP2_ENABLED} = "true" ]] || {
  exit 0
}

# Update GeoIP data
/usr/bin/geoipupdate -v &

files=(
  /etc/nginx/conf.d/90_geoip.conf
  /etc/nginx/server.d/90_geoip.conf
)

for f in "${files[@]}"
do
  dockerize -template "/app/templates$f.tmpl:$f"
done

wait
