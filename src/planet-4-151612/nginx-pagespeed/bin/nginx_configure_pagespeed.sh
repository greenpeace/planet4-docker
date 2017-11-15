#!/usr/bin/env bash
set -e

# Configure pagespeed to support downstream caching
# See: https://modpagespeed.com/doc/downstream-caching
if [ "${PAGESPEED_REBEACON_KEY}" = "$DEFAULT_PAGESPEED_REBEACON_KEY" ]; then
    _warning "$(printf "%-10s " "nginx:")" "Pagespeed rebeacon key is default, please change \$PAGESPEED_REBEACON_KEY"
else
    _good "$(printf "%-10s " "nginx:")" "PAGESPEED_REBEACON_KEY ${PAGESPEED_REBEACON_KEY}"
fi

dockerize -template /app/templates/etc/nginx/server.d/10_pagespeed.conf.tmpl:/etc/nginx/server.d/10_pagespeed.conf
