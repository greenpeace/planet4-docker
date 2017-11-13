#!/usr/bin/env bash
set -e

IFS=',' read -r -a VIRTUAL_HOSTNAMES <<< "${VIRTUAL_HOST:-}"

# If APP_HOSTNAME is not set, try first in the comma separated list of VIRTUAL_HOST,
# and finally fall back to hostname
# VIRTUAL_HOST is for use behind jwilder/nginx-proxy

APP_HOSTNAME=${APP_HOSTNAME:-${VIRTUAL_HOSTNAMES[0]:-$(hostname)}}
export APP_HOSTNAME
