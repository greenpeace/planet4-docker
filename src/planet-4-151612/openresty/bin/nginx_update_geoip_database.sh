#!/usr/bin/env bash
set -euo pipefail

# Setup weekly cron job to get updated GEOIP databases
# by running the nginx_configure_geoip2.sh script with mods

GeoIP_RANGES_FILE_PATH="/usr/share/GeoIP/geoip_update.txt"


echo "# GeoIP Update" > $GeoIP_RANGES_FILE_PATH
echo "# Generated at $(date) by $0" >> $GeoIP_RANGES_FILE_PATH
echo "" >> $GeoIP_RANGES_FILE_PATH

# Update GeoIP data
/usr/bin/geoipupdate -v >> $GeoIP_RANGES_FILE_PATH 2>&1
