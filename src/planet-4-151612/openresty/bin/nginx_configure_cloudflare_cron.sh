#!/usr/bin/env bash
set -e

# Setup daily cron job to get CloudFlare updated ips
# by running the nginx_configure_cloudflare.sh script with mods

CLOUDFLARE_DAILY_CRON_FILE_PATH="/etc/cron.daily/nginx_update_cloudflare_ips"

chmod +x $CLOUDFLARE_DAILY_CRON_FILE_PATH
