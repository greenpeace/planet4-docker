#!/usr/bin/env bash
set -euo pipefail
#Check License and Account key variables

if [[ ${GEOIP2_ENABLED} = 'true' ]]
then
  if [[ -z "${MAXMIND_ACCOUNTID}" ]]
  then
    GEOIP2_ENABLED="false"
    export GEOIP2_ENABLED
    _warning "$(printf "%-10s " "php:")" "MAXMIND_ACCOUNTID is blank, account id is required"
    _warning "$(printf "%-10s " "php:")" "disabling GeoIP"
  elif [[ -z "${MAXMIND_LICENSE}" ]]
  then
    GEOIP2_ENABLED="false"
    export GEOIP2_ENABLED
    _warning "$(printf "%-10s " "php:")" "MAXMIND_LICENSE is blank, license is required"
    _warning "$(printf "%-10s " "php:")" "disabling GeoIP"
  else
    _good "$(printf "%-10s " "php:")" "$(printf "%-22s" "maxmind.accountid:")" "${MAXMIND_ACCOUNTID//[[:alnum:]]/*}"
    _good "$(printf "%-10s " "php:")" "$(printf "%-22s" "maxmind.license:")" "${MAXMIND_LICENSE//[[:alnum:]]/*}"
    _good "$(printf "%-10s " "openresty:")" "GEOIP2 ${GEOIP2_ENABLED}"
 fi
fi

[[ ${GEOIP2_ENABLED} = "true" ]] || {
  exit 0
}

files=(
  /etc/nginx/conf.d/90_geoip.conf
  /etc/nginx/server.d/90_geoip.conf
  /etc/GeoIP.conf
)

for f in "${files[@]}"
do
  dockerize -template "/app/templates$f.tmpl:$f"
done

# Update GeoIP data
/usr/bin/geoipupdate -v &

# Setup cron job to update GeoIP data
CRON_SCHEDULE="cron.weekly"
GEOIP_WEEKLY_CRON_FILE_PATH="/etc/$CRON_SCHEDULE/nginx_update_geoip_database"
GEOIP_CRON_FILE="/app/bin/nginx_update_geoip_database.sh"
ln -s $GEOIP_CRON_FILE $GEOIP_WEEKLY_CRON_FILE_PATH

wait
