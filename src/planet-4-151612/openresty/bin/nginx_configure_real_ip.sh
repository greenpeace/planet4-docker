#!/bin/bash

if [[ ${CLOUDFLARE_ENABLED} = "true" ]]; then
  REAL_IP_HEADER=CF-Connecting-IP
else
  REAL_IP_HEADER=X-Forwarded-For
fi

export REAL_IP_HEADER

f=/etc/nginx/conf.d/10_real_ip.conf

_good "$(printf "%-10s " "openresty:")" "REAL_IP_HEADER ${REAL_IP_HEADER}"

dockerize -template "/app/templates$f.tmpl:$f"
