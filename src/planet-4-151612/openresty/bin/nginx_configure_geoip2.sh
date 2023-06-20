#!/usr/bin/env bash
set -euo pipefail
#Check License and Account key variables

[[ ${GEOIP2_ENABLED} = "true" ]] || {
  exit 0
}

[[ ${PHP_ENABLED} = "true" ]] && {
  GEOIP2_ENABLED="false"
  export GEOIP2_ENABLED
  _warning "$(printf "%-10s " "openresty:")" "PHP is not compatible with GEOIP2, disabling GEOIP2"
  exit 1
}

[[ -z "${GEOIP_ACCOUNTID}" ]] && {
  GEOIP2_ENABLED="false"
  export GEOIP2_ENABLED
  _warning "$(printf "%-10s " "openresty:")" "GEOIP_ACCOUNTID is blank, account id is required"
  _warning "$(printf "%-10s " "openresty:")" "disabling GeoIP"
  exit 1
}

[[ -z "${GEOIP_LICENSE}" ]] && {
  GEOIP2_ENABLED="false"
  export GEOIP2_ENABLED
  _warning "$(printf "%-10s " "openresty:")" "GEOIP_LICENSE is blank, license is required"
  _warning "$(printf "%-10s " "openresty:")" "disabling GeoIP"
  exit 1
}

_good "$(printf "%-10s " "openresty:")" "$(printf "%-22s" "geoip.accountid:")" "${GEOIP_ACCOUNTID//[[:alnum:]]/*}"
_good "$(printf "%-10s " "openresty:")" "$(printf "%-22s" "geoip.license:")" "${GEOIP_LICENSE//[[:alnum:]]/*}"
_good "$(printf "%-10s " "openresty:")" "GEOIP2 ${GEOIP2_ENABLED}"

files=(
  /etc/nginx/conf.d/90_geoip.conf
  /etc/nginx/server.d/90_geoip.conf
  /etc/GeoIP.conf
)

for f in "${files[@]}"; do
  dockerize -template "/app/templates$f.tmpl:$f"
done

# Setup cron job to update GeoIP data
CRON_SCHEDULE="cron.weekly"
GEOIP_WEEKLY_CRON_FILE_PATH="/etc/$CRON_SCHEDULE/nginx_update_geoip_database"
GEOIP_CRON_FILE="/app/bin/nginx_update_geoip_database.sh"
ln -s $GEOIP_CRON_FILE $GEOIP_WEEKLY_CRON_FILE_PATH

# Update GeoIP data
/usr/bin/geoipupdate -v &

wait
