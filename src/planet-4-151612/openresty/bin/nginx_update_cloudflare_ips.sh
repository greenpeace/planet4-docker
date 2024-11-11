#!/usr/bin/env bash

# This cron job is just to update the IP files and reread nginx configuration

#  (The MIT License)
#
#  Copyright (c) 2013 M.S. Babaei
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.
set -euo pipefail

# CHANGE AS PER YOUR SERVER
CLOUDFLARE_IP_RANGES_FILE_PATH_TODAY="/tmp/cloudflare-ips_today.conf"
CLOUDFLARE_IP_RANGES_FILE_PATH="/etc/nginx/conf.d/cloudflare-ips.conf"

CLOUDFLARE_IPSV4_REMOTE_FILE="https://www.cloudflare.com/ips-v4/"
CLOUDFLARE_IPSV6_REMOTE_FILE="https://www.cloudflare.com/ips-v6/"
CLOUDFLARE_IPSV4_LOCAL_FILE="/tmp/cloudflare-ips-v4"
CLOUDFLARE_IPSV6_LOCAL_FILE="/tmp/cloudflare-ips-v6"

wget --retry-connrefused --waitretry=1 -t 5 -q $CLOUDFLARE_IPSV4_REMOTE_FILE -O $CLOUDFLARE_IPSV4_LOCAL_FILE --no-check-certificate
wget --retry-connrefused --waitretry=1 -t 5 -q $CLOUDFLARE_IPSV6_REMOTE_FILE -O $CLOUDFLARE_IPSV6_LOCAL_FILE --no-check-certificate

echo "# CloudFlare IP Ranges" >$CLOUDFLARE_IP_RANGES_FILE_PATH_TODAY
# shellcheck disable=SC2129
echo "# Generated at $(date) by $0" >>$CLOUDFLARE_IP_RANGES_FILE_PATH_TODAY
echo "" >>$CLOUDFLARE_IP_RANGES_FILE_PATH_TODAY
awk '{ print "set_real_ip_from " $0 ";" }' $CLOUDFLARE_IPSV4_LOCAL_FILE >>$CLOUDFLARE_IP_RANGES_FILE_PATH_TODAY
awk '{ print "set_real_ip_from " $0 ";" }' $CLOUDFLARE_IPSV6_LOCAL_FILE >>$CLOUDFLARE_IP_RANGES_FILE_PATH_TODAY
echo "" >>$CLOUDFLARE_IP_RANGES_FILE_PATH_TODAY

chown "$APP_USER":"$APP_GROUP" $CLOUDFLARE_IP_RANGES_FILE_PATH_TODAY

mv $CLOUDFLARE_IP_RANGES_FILE_PATH_TODAY $CLOUDFLARE_IP_RANGES_FILE_PATH
rm -rf $CLOUDFLARE_IPSV4_LOCAL_FILE
rm -rf $CLOUDFLARE_IPSV6_LOCAL_FILE

# Reload configuration if running
# shellcheck disable=SC2091
if $(pgrep nginx >/dev/null 2>&1); then
  echo "# Reloading configuration ..." >>$CLOUDFLARE_IP_RANGES_FILE_PATH
  sv reload nginx
fi
