#!/usr/bin/env bash
set -e

# Setup daily cron job to get updated GEOIP databases
# by running the nginx_configure_geoip2.sh script with mods

GEOIP_WEEKLY_CRON_FILE_PATH="/etc/cron.weekly/nginx_update_geoip_database"

chmod +x $GEOIP_WEEKLY_CRON_FILE_PATH
